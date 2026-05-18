# frozen_string_literal: true

module Financials
  module ContractorSettlement
    # Pure gross / manual addition / manual reduction / charge deductions / net — no DB (TC settlement composer).
    class LineComputation
      ChargeDeductionRow = Data.define(:contractor_charge_id, :open_balance_cents, :deduct_now_cents)

      Result = Data.define(
        :gross_commission_cents,
        :manual_adjustment_positive_cents,
        :manual_adjustment_negative_cents,
        :charge_rows,
        :total_charge_deductions_cents,
        :net_settlement_cents
      )

      class << self
        # Validates explicit per-charge deductions against availability (sequential cap).
        def compute!(
          gross_commission_cents:,
          manual_positive_cents:,
          manual_negative_cents:,
          charge_deductions:
        )
          gross = gross_commission_cents.to_i
          pos = manual_positive_cents.to_i
          neg = manual_negative_cents.to_i

          available = gross + pos - neg
          if available.negative?
            raise ArgumentError, "Manual adjustments would make settlement negative before charges"
          end

          total_deductions = 0
          rows = []
          running = available

          Array(charge_deductions).each do |raw|
            row = normalize_row(raw)
            d = row.deduct_now_cents
            ob = row.open_balance_cents

            if d.negative?
              raise ArgumentError, "Charge deduction cannot be negative (charge #{row.contractor_charge_id})"
            end
            if d > ob
              raise ArgumentError, "Deduction cannot exceed open balance for charge #{row.contractor_charge_id}"
            end
            if d > running
              raise ArgumentError, "Charge deductions exceed available settlement amount"
            end

            running -= d
            total_deductions += d
            rows << row
          end

          net = available - total_deductions
          if net.negative?
            raise ArgumentError, "Net settlement cannot be negative"
          end

          Result.new(
            gross_commission_cents: gross,
            manual_adjustment_positive_cents: pos,
            manual_adjustment_negative_cents: neg,
            charge_rows: rows,
            total_charge_deductions_cents: total_deductions,
            net_settlement_cents: net
          )
        end

        # Sequential waterfall: each charge deducts up to min(open_balance, remaining_available).
        # +charges_in_order+ must respond to +id+ and +open_balance_cents+.
        def propose_waterfall!(
          gross_commission_cents:,
          manual_positive_cents:,
          manual_negative_cents:,
          charges_in_order:
        )
          gross = gross_commission_cents.to_i
          pos = manual_positive_cents.to_i
          neg = manual_negative_cents.to_i
          available = gross + pos - neg
          if available.negative?
            raise ArgumentError, "Manual adjustments would make settlement negative before charges"
          end

          deductions = []
          charges_in_order.each do |ch|
            next if ch.open_balance_cents.to_i <= 0

            deduct = [ ch.open_balance_cents.to_i, available ].min
            next if deduct <= 0

            deductions << ChargeDeductionRow.new(
              contractor_charge_id: ch.id,
              open_balance_cents: ch.open_balance_cents.to_i,
              deduct_now_cents: deduct
            )
            available -= deduct
          end

          compute!(
            gross_commission_cents: gross,
            manual_positive_cents: pos,
            manual_negative_cents: neg,
            charge_deductions: deductions
          )
        end

        private

        def normalize_row(raw)
          case raw
          when ChargeDeductionRow
            raw
          when Hash
            ChargeDeductionRow.new(
              contractor_charge_id: raw.fetch(:contractor_charge_id),
              open_balance_cents: raw.fetch(:open_balance_cents).to_i,
              deduct_now_cents: raw.fetch(:deduct_now_cents).to_i
            )
          else
            raise ArgumentError, "Invalid charge deduction row: #{raw.class}"
          end
        end
      end
    end
  end
end

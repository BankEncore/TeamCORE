# frozen_string_literal: true

module Financials
  module ContractorSettlement
    class ComposeLine
      def self.call(run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
        manual_positive: 0, manual_negative: 0)
        new(
          run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
          manual_positive:, manual_negative:
        ).call
      end

      def initialize(run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
        manual_positive:, manual_negative:)
        @run = run
        @engagement = engagement
        @actor = actor
        @revenue_input_ids = Array(revenue_input_ids).map(&:to_i).reject(&:zero?)
        @commission_calculation_ids = Array(commission_calculation_ids).map(&:to_i).reject(&:zero?)
        @contractor_charge_ids = Array(contractor_charge_ids).map(&:to_i).reject(&:zero?)
        @manual_positive = manual_positive.to_i
        @manual_negative = manual_negative.to_i
      end

      def call
        raise ArgumentError, "Run must be draft" unless @run.status == "draft"
        raise ArgumentError, "Engagement not eligible" unless @engagement.allows_contractor_charges_and_settlement?

        CommissionCalculation.transaction do
          rev_inputs = RevenueInput.where(id: @revenue_input_ids, engagement_id: @engagement.id, agency_id: @run.agency_id)
          calc_ids = @commission_calculation_ids.dup
          if calc_ids.empty? && @revenue_input_ids.any?
            calc_ids = CommissionCalculation.where(revenue_input_id: rev_inputs.select(:id)).pluck(:id)
          end
          calcs = CommissionCalculation.where(id: calc_ids, engagement_id: @engagement.id, agency_id: @run.agency_id)

          gross = calcs.sum(:gross_commission_pay_cents)

          line = ContractorSettlementLine.create!(
            contractor_settlement_run: @run,
            agency_id: @run.agency_id,
            engagement: @engagement,
            gross_commission_cents: gross,
            charge_deductions_cents: 0,
            manual_adjustment_positive_cents: @manual_positive,
            manual_adjustment_negative_cents: @manual_negative,
            net_settlement_cents: 0
          )

          rev_inputs.find_each do |ri|
            ContractorSettlementLineRevenueInput.create!(contractor_settlement_line: line, revenue_input: ri)
          end
          calcs.find_each do |c|
            ContractorSettlementLineCommissionCalculation.create!(contractor_settlement_line: line, commission_calculation: c)
          end

          available = gross + @manual_positive - @manual_negative
          raise ArgumentError, "Manual adjustments would make settlement negative before charges" if available.negative?

          total_deductions = 0
          charges = ContractorCharge.where(
            id: @contractor_charge_ids,
            engagement_id: @engagement.id,
            agency_id: @run.agency_id
          ).order(:id)

          charges.find_each do |charge|
            next if charge.open_balance_cents <= 0

            deduct = [ charge.open_balance_cents, available ].min
            next if deduct <= 0

            ContractorChargeRecovery.create!(
              agency_id: @run.agency_id,
              contractor_charge: charge,
              contractor_settlement_line: line,
              source_type: "settlement_deduction",
              amount_cents: deduct,
              occurred_on: Date.current,
              actor_id: @actor&.id,
              notes: "Settlement #{@run.id} line #{line.id}"
            )
            charge.update!(
              open_balance_cents: charge.open_balance_cents - deduct,
              status: charge.open_balance_cents - deduct <= 0 ? "closed" : charge.status
            )
            total_deductions += deduct
            available -= deduct
          end

          net = gross + @manual_positive - @manual_negative - total_deductions
          raise ArgumentError, "Net settlement cannot be negative" if net.negative?

          line.update!(
            charge_deductions_cents: total_deductions,
            net_settlement_cents: net
          )

          line
        end
      end
    end
  end
end

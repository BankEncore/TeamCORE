# frozen_string_literal: true

module Financials
  module ContractorSettlement
    # Read-only settlement preview: candidates + LineComputation (no DB writes).
    class PreviewLine
      Result = Data.define(
        :commission_candidate_rows,
        :charge_candidate_rows,
        :selected_commission_calculation_ids,
        :selected_contractor_charge_ids,
        :computation,
        :warnings
      )

      class << self
        # +commission_calculation_ids+ / +contractor_charge_ids+: nil = use composer defaults; [] = explicit empty.
        def call(
          run:,
          engagement:,
          include_future_due: false,
          manual_positive_cents: 0,
          manual_negative_cents: 0,
          commission_calculation_ids: nil,
          contractor_charge_ids: nil,
          charge_deductions_cents_by_id: nil
        )
          raise ArgumentError, "Run must be draft or calculated" unless run.status.in?(%w[draft calculated])
          raise ArgumentError, "Engagement not eligible" unless engagement.allows_contractor_charges_and_settlement?

          commission_candidate_rows = SettlementComposerCandidates.commission_rows(run:, engagement:)
          charge_candidate_rows = SettlementComposerCandidates.charge_rows(run:, engagement:, include_future_due:)

          selected_calc_ids =
            if commission_calculation_ids.nil?
              commission_candidate_rows
                .select { |r| r.default_checked && r.exclusion_reason.nil? }
                .map { |r| r.calculation.id }
            else
              commission_calculation_ids.map(&:to_i).reject(&:zero?).uniq
            end

          selected_charge_ids =
            if contractor_charge_ids.nil?
              charge_candidate_rows.select(&:default_checked).map { |r| r.charge.id }
            else
              contractor_charge_ids.map(&:to_i).reject(&:zero?).uniq
            end

          warnings = []
          calcs =
            CommissionCalculation
              .where(id: selected_calc_ids, engagement_id: engagement.id, agency_id: run.agency_id)
              .includes(:revenue_input)

          missing_calc_ids = selected_calc_ids - calcs.pluck(:id)
          unless missing_calc_ids.empty?
            warnings << { code: :unknown_commission_calculation_ids, ids: missing_calc_ids }
          end

          settled = SettlementComposerCandidates.settled_commission_calculation_ids(agency_id: run.agency_id)
          calcs.each do |c|
            warnings << { code: :draft_commission_calculation, id: c.id } if c.status != "finalized"
            warnings << { code: :already_settled_commission_calculation, id: c.id } if settled.include?(c.id)
            if c.revenue_input.present?
              unless periods_overlap?(c.revenue_input.period_start_on, c.revenue_input.period_end_on, run.period_start_on, run.period_end_on)
                warnings << { code: :commission_outside_run_period, id: c.id }
              end
            else
              warnings << { code: :commission_missing_revenue_input, id: c.id }
            end
          end

          gross = calcs.sum(&:gross_commission_pay_cents)

          charges =
            ContractorCharge.where(
              id: selected_charge_ids,
              engagement_id: engagement.id,
              agency_id: run.agency_id,
              status: "open"
            ).where("open_balance_cents > 0")

          ordered_selected =
            SettlementComposerCandidates
              .ordered_open_charges(run:, engagement:)
              .where(id: selected_charge_ids)

          missing_charge_ids = selected_charge_ids - charges.pluck(:id)
          unless missing_charge_ids.empty?
            warnings << { code: :unknown_or_ineligible_charge_ids, ids: missing_charge_ids }
          end

          computation =
            if charge_deductions_cents_by_id.blank?
              LineComputation.propose_waterfall!(
                gross_commission_cents: gross,
                manual_positive_cents: manual_positive_cents.to_i,
                manual_negative_cents: manual_negative_cents.to_i,
                charges_in_order: ordered_selected.to_a
              )
            else
              rows =
                ordered_selected.to_a.map do |ch|
                  h =
                    if charge_deductions_cents_by_id.respond_to?(:to_unsafe_h)
                      charge_deductions_cents_by_id.to_unsafe_h
                    else
                      charge_deductions_cents_by_id
                    end
                  h = h.stringify_keys
                  deduct = h[ch.id.to_s]
                  if deduct.nil?
                    raise ArgumentError, "Missing deduction amount for selected charge #{ch.id}"
                  end

                  LineComputation::ChargeDeductionRow.new(
                    contractor_charge_id: ch.id,
                    open_balance_cents: ch.open_balance_cents,
                    deduct_now_cents: deduct.to_i
                  )
                end

              LineComputation.compute!(
                gross_commission_cents: gross,
                manual_positive_cents: manual_positive_cents.to_i,
                manual_negative_cents: manual_negative_cents.to_i,
                charge_deductions: rows
              )
            end

          Result.new(
            commission_candidate_rows:,
            charge_candidate_rows:,
            selected_commission_calculation_ids: selected_calc_ids,
            selected_contractor_charge_ids: selected_charge_ids,
            computation:,
            warnings:
          )
        end

        def periods_overlap?(a_start, a_end, b_start, b_end)
          a_start <= b_end && a_end >= b_start
        end
      end
    end
  end
end

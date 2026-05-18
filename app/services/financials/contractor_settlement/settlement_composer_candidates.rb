# frozen_string_literal: true

module Financials
  module ContractorSettlement
    # Discover commission calculations and contractor charges for the settlement composer UI (read-only queries).
    class SettlementComposerCandidates
      CommissionRow = Data.define(:calculation, :default_checked, :exclusion_reason)
      ChargeRow = Data.define(:charge, :default_checked, :warnings)

      class << self
        # CommissionCalculation ids already tied to a non-voided settlement run (Decision §1).
        def settled_commission_calculation_ids(agency_id:)
          CommissionCalculation
            .joins(contractor_settlement_line_commission_calculations: { contractor_settlement_line: :contractor_settlement_run })
            .where(agency_id: agency_id)
            .where.not(contractor_settlement_runs: { status: "voided" })
            .distinct
            .pluck(:id)
            .to_set
        end

        # Finalized calcs for engagement whose revenue_input period overlaps the settlement run period.
        def commission_candidate_scope(run:, engagement:)
          CommissionCalculation
            .where(agency_id: run.agency_id, engagement_id: engagement.id, status: "finalized")
            .joins(:revenue_input)
            .where(
              "revenue_inputs.period_start_on <= ? AND revenue_inputs.period_end_on >= ?",
              run.period_end_on,
              run.period_start_on
            )
            .includes(:revenue_input)
            .order(:id)
        end

        def commission_rows(run:, engagement:)
          settled = settled_commission_calculation_ids(agency_id: run.agency_id)
          commission_candidate_scope(run:, engagement:).map do |calc|
            if settled.include?(calc.id)
              CommissionRow.new(calculation: calc, default_checked: false, exclusion_reason: :already_on_run)
            else
              CommissionRow.new(calculation: calc, default_checked: true, exclusion_reason: nil)
            end
          end
        end

        # Open charges with positive balance; order due_on NULLS FIRST then due_on, id (Decision §3).
        def ordered_open_charges(run:, engagement:)
          ContractorCharge
            .where(agency_id: run.agency_id, engagement_id: engagement.id, status: "open")
            .where("open_balance_cents > 0")
            .order(Arel.sql("due_on IS NULL DESC"), :due_on, :id)
        end

        def charge_rows(run:, engagement:, include_future_due: false)
          ordered_open_charges(run:, engagement:).map do |charge|
            warnings = []
            if charge.due_on.present? && charge.due_on > run.period_end_on
              warnings << :due_after_period_end
            end

            default_checked =
              if charge.due_on.blank? || charge.due_on <= run.period_end_on
                true
              elsif include_future_due
                false
              else
                false
              end

            ChargeRow.new(charge:, default_checked:, warnings:)
          end
        end
      end
    end
  end
end

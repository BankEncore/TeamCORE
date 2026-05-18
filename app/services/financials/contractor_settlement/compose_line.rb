# frozen_string_literal: true

module Financials
  module ContractorSettlement
    class ComposeLine
      def self.call(run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
        manual_positive: 0, manual_negative: 0, charge_deductions_cents_by_id: nil)
        new(
          run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
          manual_positive:, manual_negative:, charge_deductions_cents_by_id:
        ).call
      end

      def initialize(run:, engagement:, actor:, revenue_input_ids:, commission_calculation_ids:, contractor_charge_ids:,
        manual_positive:, manual_negative:, charge_deductions_cents_by_id:)
        @run = run
        @engagement = engagement
        @actor = actor
        @revenue_input_ids = Array(revenue_input_ids).map(&:to_i).reject(&:zero?)
        @commission_calculation_ids = Array(commission_calculation_ids).map(&:to_i).reject(&:zero?)
        @contractor_charge_ids = Array(contractor_charge_ids).map(&:to_i).reject(&:zero?)
        @manual_positive = manual_positive.to_i
        @manual_negative = manual_negative.to_i
        @charge_deductions_cents_by_id =
          if charge_deductions_cents_by_id.nil?
            nil
          elsif charge_deductions_cents_by_id.respond_to?(:to_unsafe_h)
            charge_deductions_cents_by_id.to_unsafe_h.stringify_keys.transform_values(&:to_i)
          else
            charge_deductions_cents_by_id.stringify_keys.transform_values(&:to_i)
          end
      end

      def call
        raise ArgumentError, "Run must be draft or calculated" unless @run.status.in?(%w[draft calculated])
        raise ArgumentError, "Engagement not eligible" unless @engagement.allows_contractor_charges_and_settlement?

        if ContractorSettlementLine.where(contractor_settlement_run_id: @run.id, engagement_id: @engagement.id).exists?
          raise ArgumentError, "A settlement line already exists for this engagement on this run."
        end

        CommissionCalculation.transaction do
          calc_ids = resolved_commission_calculation_ids
          calcs =
            CommissionCalculation
              .where(id: calc_ids, engagement_id: @engagement.id, agency_id: @run.agency_id)
              .includes(:revenue_input)

          validate_commission_selection!(calcs, calc_ids)

          gross = calcs.sum(&:gross_commission_pay_cents)

          rev_ids = revenue_input_ids_for_lines(calcs)
          rev_inputs = RevenueInput.where(id: rev_ids, engagement_id: @engagement.id, agency_id: @run.agency_id)

          ordered_charges =
            SettlementComposerCandidates
              .ordered_open_charges(run: @run, engagement: @engagement)
              .where(id: @contractor_charge_ids)

          computation =
            if @charge_deductions_cents_by_id.blank?
              LineComputation.propose_waterfall!(
                gross_commission_cents: gross,
                manual_positive_cents: @manual_positive,
                manual_negative_cents: @manual_negative,
                charges_in_order: ordered_charges.to_a
              )
            else
              rows =
                ordered_charges.to_a.map do |ch|
                  deduct = @charge_deductions_cents_by_id[ch.id.to_s]
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
                manual_positive_cents: @manual_positive,
                manual_negative_cents: @manual_negative,
                charge_deductions: rows
              )
            end

          line = ContractorSettlementLine.create!(
            contractor_settlement_run: @run,
            agency_id: @run.agency_id,
            engagement: @engagement,
            gross_commission_cents: computation.gross_commission_cents,
            charge_deductions_cents: 0,
            manual_adjustment_positive_cents: computation.manual_adjustment_positive_cents,
            manual_adjustment_negative_cents: computation.manual_adjustment_negative_cents,
            net_settlement_cents: 0
          )

          rev_inputs.find_each do |ri|
            ContractorSettlementLineRevenueInput.create!(contractor_settlement_line: line, revenue_input: ri)
          end
          calcs.find_each do |c|
            ContractorSettlementLineCommissionCalculation.create!(contractor_settlement_line: line, commission_calculation: c)
          end

          computation.charge_rows.each do |row|
            deduct = row.deduct_now_cents
            next if deduct <= 0

            charge = ContractorCharge.lock.find_by!(id: row.contractor_charge_id, agency_id: @run.agency_id)
            new_balance = charge.open_balance_cents - deduct

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
              open_balance_cents: new_balance,
              status: new_balance <= 0 ? "closed" : charge.status
            )
          end

          line.update!(
            charge_deductions_cents: computation.total_charge_deductions_cents,
            net_settlement_cents: computation.net_settlement_cents
          )

          line
        end
      end

      private

      def resolved_commission_calculation_ids
        calc_ids = @commission_calculation_ids.dup
        if calc_ids.empty? && @revenue_input_ids.any?
          rev_inputs = RevenueInput.where(id: @revenue_input_ids, engagement_id: @engagement.id, agency_id: @run.agency_id)
          calc_ids = CommissionCalculation.where(revenue_input_id: rev_inputs.select(:id), engagement_id: @engagement.id,
            agency_id: @run.agency_id).pluck(:id)
        end
        calc_ids.uniq
      end

      def revenue_input_ids_for_lines(calcs)
        from_calcs = calcs.filter_map(&:revenue_input_id).uniq
        (@revenue_input_ids + from_calcs).uniq
      end

      def validate_commission_selection!(calcs, expected_calc_ids)
        missing = expected_calc_ids - calcs.pluck(:id)
        if missing.any?
          raise ArgumentError, "Unknown or ineligible commission calculation id(s): #{missing.sort.join(', ')}"
        end

        settled = SettlementComposerCandidates.settled_commission_calculation_ids(agency_id: @run.agency_id)
        calcs.each do |c|
          raise ArgumentError, "Commission calculation #{c.id} is already on a non-voided settlement run." if settled.include?(c.id)
          raise ArgumentError, "Commission calculation #{c.id} must be finalized before settlement." unless c.status == "finalized"
          if c.revenue_input.blank?
            raise ArgumentError, "Commission calculation #{c.id} is missing a revenue input."
          end

          unless PreviewLine.periods_overlap?(
            c.revenue_input.period_start_on,
            c.revenue_input.period_end_on,
            @run.period_start_on,
            @run.period_end_on
          )
            raise ArgumentError, "Commission calculation #{c.id} revenue period does not overlap the settlement run period."
          end
        end
      end
    end
  end
end

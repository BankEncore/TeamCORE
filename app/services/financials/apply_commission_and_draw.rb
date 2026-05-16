# frozen_string_literal: true

module Financials
  # Builds or replaces a draft CommissionCalculation for a revenue_input using assignment snapshots
  # and employee-only minimum commission draw rules (developer brief / TC-15–TC-16).
  class ApplyCommissionAndDraw
    def self.call(revenue_input:, actor: nil)
      new(revenue_input:, actor:).call
    end

    def initialize(revenue_input:, actor:)
      @revenue_input = revenue_input
      @actor = actor
    end

    def call
      engagement = @revenue_input.engagement
      agency = @revenue_input.agency
      pay_period = @revenue_input.pay_period
      as_of = pay_period&.end_on || @revenue_input.period_end_on
      assignment = CompensationPlanAssignment.current_for_engagement(engagement, as_of:)
      raise ArgumentError, "No compensation plan assignment effective on #{as_of}" unless assignment
      raise ArgumentError, "Assignment missing commission rate" unless assignment.snapshot_commission_rate_bps.to_i.positive?

      rate = assignment.snapshot_commission_rate_bps
      revenue_cents = @revenue_input.commissionable_revenue_cents
      raw_commission = (revenue_cents * rate) / 10_000

      draw_added = 0
      draw_recovery = 0
      gross_pay = raw_commission
      ending_draw = 0

      if engagement.allows_employee_commission_draw?
        min_amt = assignment.snapshot_minimum_amount_cents.to_i
        balance_record = CommissionDrawBalance.find_or_initialize_by(engagement_id: engagement.id, agency_id: agency.id)
        balance_record.balance_cents = 0 if balance_record.new_record?
        balance_start = balance_record.balance_cents

        if min_amt.positive?
          if raw_commission < min_amt
            draw_added = min_amt - raw_commission
            gross_pay = min_amt
            ending_draw = balance_start + draw_added
            draw_recovery = 0
          else
            excess = raw_commission - min_amt
            draw_recovery = [excess, balance_start].min
            gross_pay = raw_commission - draw_recovery
            ending_draw = balance_start - draw_recovery
          end
        else
          gross_pay = raw_commission
          ending_draw = balance_start
        end

        calc = nil
        CommissionCalculation.transaction do
          calc = upsert_calculation!(
            engagement:,
            agency:,
            pay_period:,
            rate:,
            revenue_cents:,
            raw_commission:,
            draw_added:,
            draw_recovery:,
            gross_pay:,
            ending_draw:
          )
          balance_record.balance_cents = ending_draw
          balance_record.save!
          record_draw_events!(engagement:, agency:, calc:, balance_start:, draw_added:, draw_recovery:, ending_draw:)
        end
      else
        # Contractor (or other): flat commission only, no draw ledger
        gross_pay = raw_commission
        ending_draw = 0
        upsert_calculation!(
          engagement:,
          agency:,
          pay_period:,
          rate:,
          revenue_cents:,
          raw_commission:,
          draw_added: 0,
          draw_recovery: 0,
          gross_pay:,
          ending_draw: 0
        )
      end

      true
    end

    private

    def upsert_calculation!(engagement:, agency:, pay_period:, rate:, revenue_cents:, raw_commission:, draw_added:, draw_recovery:, gross_pay:, ending_draw:)
      existing = CommissionCalculation.find_by(revenue_input_id: @revenue_input.id)
      if existing&.finalized?
        raise ArgumentError, "Cannot recalculate: commission for this revenue input is finalized"
      end

      attrs = {
        agency_id: agency.id,
        engagement_id: engagement.id,
        pay_period_id: pay_period&.id,
        revenue_input_id: @revenue_input.id,
        commission_rate_bps: rate,
        commissionable_revenue_cents: revenue_cents,
        calculated_commission_cents: raw_commission,
        draw_added_cents: draw_added,
        draw_recovery_cents: draw_recovery,
        gross_commission_pay_cents: gross_pay,
        ending_draw_balance_cents: ending_draw,
        status: "draft"
      }
      if existing
        existing.update!(attrs)
        existing
      else
        CommissionCalculation.create!(attrs)
      end
    end

    def record_draw_events!(engagement:, agency:, calc:, balance_start:, draw_added:, draw_recovery:, ending_draw:)
      return unless draw_added.positive? || draw_recovery.positive?

      if draw_added.positive?
        DrawBalanceEvent.create!(
          agency_id: agency.id,
          engagement_id: engagement.id,
          commission_calculation_id: calc.id,
          event_type: "draw_added",
          amount_cents: draw_added,
          actor_id: @actor&.id,
          reason: "Minimum commission draw (TC-16)"
        )
      end

      if draw_recovery.positive?
        DrawBalanceEvent.create!(
          agency_id: agency.id,
          engagement_id: engagement.id,
          commission_calculation_id: calc.id,
          event_type: "recovery",
          amount_cents: draw_recovery,
          actor_id: @actor&.id,
          reason: "Draw recovery from commission above minimum"
        )
      end
    end
  end
end

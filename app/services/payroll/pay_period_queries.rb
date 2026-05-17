# frozen_string_literal: true

module Payroll
  # Read/query helpers — keep reporting semantics out of Active Record models.
  module PayPeriodQueries
    module_function

    def current_open_period_for_today(agency, today = Date.current)
      agency.pay_periods.open_periods
        .where("pay_periods.start_on <= ? AND pay_periods.end_on >= ?", today, today)
        .order(start_on: :desc)
        .first
    end

    def open_periods(agency)
      agency.pay_periods.open_periods.order(start_on: :desc)
    end

    def export_history(pay_period)
      pay_period.payroll_exports.includes(:exported_by).ordered
    end

    # Placeholders until timesheets ship (TC‑23 / TC‑24).
    def missing_timesheets_count(_agency, _pay_period)
      0
    end

    # Placeholders until approvals ship (TC‑24).
    def pending_approvals_count(_agency, _pay_period)
      0
    end
  end
end

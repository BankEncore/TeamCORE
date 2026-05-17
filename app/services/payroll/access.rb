# frozen_string_literal: true

module Payroll
  # Thin capability hooks — TC‑23a explicitly avoids full RBAC (ADR / Phase 5 plan).
  module Access
    module_function

    def can_close_pay_period?(user:, agency:)
      user.present? && user.agencies.exists?(agency.id)
    end

    def can_generate_pay_periods?(user:, agency:)
      user.present? && user.agencies.exists?(agency.id)
    end

    # MVP: agency-scoped user may act on weekly timesheet approvals.
    # Direct supervisor enforcement is deferred until role/identity mapping exists.
    def can_manage_weekly_timesheet_approval?(user:, weekly_timesheet:)
      return false if user.blank? || weekly_timesheet.blank?

      agency_id = weekly_timesheet.engagement&.agency_id
      return false if agency_id.blank?

      user.agencies.exists?(agency_id)
    end

    # MVP: agency-scoped user may manage employee leave requests and balances.
    def can_manage_leave_request?(user:, leave_request:)
      return false if user.blank? || leave_request.blank?

      agency_id = leave_request.engagement&.agency_id
      return false if agency_id.blank?

      user.agencies.exists?(agency_id)
    end

    def can_adjust_leave_balance?(user:, leave_balance:)
      return false if user.blank? || leave_balance.blank?

      agency_id = leave_balance.engagement&.agency_id
      return false if agency_id.blank?

      user.agencies.exists?(agency_id)
    end
  end
end

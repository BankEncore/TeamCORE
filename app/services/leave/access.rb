# frozen_string_literal: true

module Leave
  # Thin capability hooks for leave workflows; delegates to Payroll::Access until TC-29 RBAC.
  module Access
    module_function

    def can_manage_leave_request?(user:, leave_request:)
      Payroll::Access.can_manage_leave_request?(user:, leave_request:)
    end

    def can_adjust_leave_balance?(user:, leave_balance:)
      Payroll::Access.can_adjust_leave_balance?(user:, leave_balance:)
    end
  end
end

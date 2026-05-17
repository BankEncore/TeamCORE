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
  end
end

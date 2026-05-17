# frozen_string_literal: true

module Payroll
  # Labels leave requests as projected vs payroll-visible (approved only), mirroring overtime presenter posture.
  class LeavePayrollVisibilityPresenter
    attr_reader :leave_request

    def self.for_leave_request(leave_request)
      new(leave_request)
    end

    def initialize(leave_request)
      @leave_request = leave_request
    end

    def visibility_mode
      leave_request.status == "approved" ? :payroll_visible : :projected
    end

    def visibility_label
      visibility_mode == :payroll_visible ? "Payroll-visible leave" : "Projected leave"
    end
  end
end

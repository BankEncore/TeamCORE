# frozen_string_literal: true

module Payroll
  PayrollSummary = Data.define(
    :regular_hours,
    :overtime_hours,
    :paid_leave_hours,
    :unpaid_leave_hours,
    :total_paid_hours,
    :hours_by_earning_code
  ) do
    # Sum of paid + unpaid absence hours (informational; separate from worked REG/OT).
    def leave_hours
      paid_leave_hours + unpaid_leave_hours
    end

    def self.empty
      z = BigDecimal("0")
      new(
        regular_hours: z,
        overtime_hours: z,
        paid_leave_hours: z,
        unpaid_leave_hours: z,
        total_paid_hours: z,
        hours_by_earning_code: {}
      )
    end
  end
end

# frozen_string_literal: true

module Payroll
  PayrollSummary = Data.define(
    :regular_hours,
    :overtime_hours,
    :leave_hours,
    :total_paid_hours,
    :hours_by_earning_code
  ) do
    def self.empty
      new(
        regular_hours: BigDecimal("0"),
        overtime_hours: BigDecimal("0"),
        leave_hours: BigDecimal("0"),
        total_paid_hours: BigDecimal("0"),
        hours_by_earning_code: {}
      )
    end
  end
end

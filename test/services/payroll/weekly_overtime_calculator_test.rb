# frozen_string_literal: true

require "test_helper"

class Payroll::WeeklyOvertimeCalculatorTest < ActiveSupport::TestCase
  test "hours below threshold are all regular" do
    mon = Date.new(2024, 6, 3)
    daily = { mon => 8, mon + 1 => 8, mon + 2 => 8, mon + 3 => 8, mon + 4 => 8 }
    r = Payroll::WeeklyOvertimeCalculator.compute(
      workweek_start: mon,
      workweek_end: mon + 6,
      daily_worked_hours: daily,
      threshold_hours: 40
    )
    assert_equal BigDecimal("40"), r.regular_hours
    assert_equal BigDecimal("0"), r.overtime_hours
  end

  test "hours above threshold split into ot" do
    mon = Date.new(2024, 6, 3)
    daily = { mon => 10, mon + 1 => 10, mon + 2 => 10, mon + 3 => 10, mon + 4 => 10 }
    r = Payroll::WeeklyOvertimeCalculator.compute(
      workweek_start: mon,
      workweek_end: mon + 6,
      daily_worked_hours: daily,
      threshold_hours: 40
    )
    assert_equal BigDecimal("40"), r.regular_hours
    assert_equal BigDecimal("10"), r.overtime_hours
  end
end

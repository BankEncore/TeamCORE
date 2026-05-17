# frozen_string_literal: true

require "test_helper"

class Payroll::PayPeriodWorkweeksTest < ActiveSupport::TestCase
  test "each_intersecting yields every workweek overlapping pay period" do
    pay_period = PayPeriod.new(start_on: Date.new(2025, 3, 3), end_on: Date.new(2025, 3, 23))
    weeks = Payroll::PayPeriodWorkweeks.each_intersecting(pay_period, workweek_starts_on: 1).to_a
    assert_equal 3, weeks.size
    assert_includes weeks, [ Date.new(2025, 3, 3), Date.new(2025, 3, 9) ]
    assert_includes weeks, [ Date.new(2025, 3, 10), Date.new(2025, 3, 16) ]
    assert_includes weeks, [ Date.new(2025, 3, 17), Date.new(2025, 3, 23) ]
  end
end

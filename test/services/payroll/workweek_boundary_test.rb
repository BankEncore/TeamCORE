# frozen_string_literal: true

require "test_helper"

class Payroll::WorkweekBoundaryTest < ActiveSupport::TestCase
  test "week containing Wednesday when week starts Monday" do
    wed = Date.new(2024, 6, 5)
    start_d, end_d = Payroll::WorkweekBoundary.range_for(wed, workweek_starts_on: 1)
    assert_equal Date.new(2024, 6, 3), start_d
    assert_equal Date.new(2024, 6, 9), end_d
  end

  test "week containing Wednesday when week starts Sunday" do
    wed = Date.new(2024, 6, 5)
    start_d, end_d = Payroll::WorkweekBoundary.range_for(wed, workweek_starts_on: 0)
    assert_equal Date.new(2024, 6, 2), start_d
    assert_equal Date.new(2024, 6, 8), end_d
  end
end

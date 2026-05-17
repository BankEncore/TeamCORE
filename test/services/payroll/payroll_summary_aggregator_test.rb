# frozen_string_literal: true

require "test_helper"

class Payroll::PayrollSummaryAggregatorTest < ActiveSupport::TestCase
  test "returns empty summary until time and leave sources exist" do
    agency, = p4_agency_user!
    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 1, 1),
      end_on: Date.new(2025, 1, 15),
      payroll_frequency: "legacy",
      status: "open"
    )
    summary = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp).call
    assert_equal BigDecimal("0"), summary.regular_hours
    assert_equal({}, summary.hours_by_earning_code)
  end
end

# frozen_string_literal: true

require "test_helper"

class Payroll::CommissionDrawAssemblyTest < ActiveSupport::TestCase
  test "line_candidates is empty until upstream wiring exists" do
    agency, = p4_agency_user!
    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 2, 1),
      end_on: Date.new(2025, 2, 15),
      label: "Feb",
      payroll_frequency: "legacy",
      status: "open"
    )
    assert_equal [], Payroll::CommissionDrawAssembly.line_candidates(agency:, pay_period: pp, engagement_ids: [])
  end
end

# frozen_string_literal: true

require "test_helper"

class ContractorSettlementRunTest < ActiveSupport::TestCase
  test "period_end_on must be on or after period_start_on" do
    agency, = p4_agency_user!
    run = ContractorSettlementRun.new(
      agency:,
      period_start_on: Date.new(2024, 3, 10),
      period_end_on: Date.new(2024, 3, 1),
      status: "draft"
    )

    assert_not run.valid?
    assert run.errors[:period_end_on].present?
  end
end

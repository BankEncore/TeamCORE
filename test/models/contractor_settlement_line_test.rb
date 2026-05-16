# frozen_string_literal: true

require "test_helper"

class ContractorSettlementLineTest < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @ic = p4_active_ic!(@agency)
    @ee = p4_active_employee!(@agency)
    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
  end

  test "rejects negative net settlement" do
    line = ContractorSettlementLine.new(
      contractor_settlement_run: @run,
      agency: @agency,
      engagement: @ic[:engagement],
      gross_commission_cents: 100,
      charge_deductions_cents: 0,
      manual_adjustment_positive_cents: 0,
      manual_adjustment_negative_cents: 0,
      net_settlement_cents: -1
    )

    assert_not line.valid?
    assert_includes line.errors[:net_settlement_cents].join, "negative"
  end

  test "rejects employee engagement" do
    line = ContractorSettlementLine.new(
      contractor_settlement_run: @run,
      agency: @agency,
      engagement: @ee[:engagement],
      gross_commission_cents: 0,
      charge_deductions_cents: 0,
      manual_adjustment_positive_cents: 0,
      manual_adjustment_negative_cents: 0,
      net_settlement_cents: 0
    )

    assert_not line.valid?
    assert_includes line.errors[:engagement].join, "contractor"
  end
end

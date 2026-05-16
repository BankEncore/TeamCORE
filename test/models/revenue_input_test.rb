# frozen_string_literal: true

require "test_helper"

class RevenueInputTest < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @ee = p4_active_employee!(@agency)
    @ic = p4_active_ic!(@agency)
    @pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 1, 1), end_on: Date.new(2024, 1, 15))
  end

  test "employee engagement requires pay_period" do
    ri = RevenueInput.new(
      agency: @agency,
      engagement: @ee[:engagement],
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 100,
      source_type: "manual"
    )

    assert_not ri.valid?
    assert_includes ri.errors[:pay_period_id].join, "required"
  end

  test "contractor engagement allows blank pay_period" do
    ri = RevenueInput.new(
      agency: @agency,
      engagement: @ic[:engagement],
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 100,
      source_type: "manual"
    )

    assert ri.valid?, ri.errors.full_messages.join(", ")
  end

  test "rejects invalid source_type" do
    ri = RevenueInput.new(
      agency: @agency,
      engagement: @ic[:engagement],
      pay_period: nil,
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 100,
      source_type: "bogus"
    )

    assert_not ri.valid?
    assert ri.errors[:source_type].present?
  end
end

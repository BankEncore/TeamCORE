# frozen_string_literal: true

require "test_helper"

class FinancialsApplyCommissionAndDrawTest < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @ee = p4_active_employee!(@agency)
    @ic = p4_active_ic!(@agency)
    @pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 1, 1), end_on: Date.new(2024, 1, 15), label: "P1")
  end

  test "employee below minimum accrues draw and records draw_added event" do
    plan = p4_commission_plan!(@agency, rate_bps: 1000, minimum_cents: 200_000)
    p4_assign_plan!(agency: @agency, engagement: @ee[:engagement], plan:)

    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: @pp,
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 1_500_000,
      source_type: "manual"
    )

    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: nil)

    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    assert_equal 150_000, calc.calculated_commission_cents
    assert_equal 50_000, calc.draw_added_cents
    assert_equal 200_000, calc.gross_commission_pay_cents
    assert_equal 50_000, calc.ending_draw_balance_cents

    bal = CommissionDrawBalance.find_by!(engagement_id: @ee[:engagement].id)
    assert_equal 50_000, bal.balance_cents

    assert_equal 1, DrawBalanceEvent.where(engagement: @ee[:engagement], event_type: "draw_added").count
  end

  test "employee above minimum recovers prior draw balance" do
    plan = p4_commission_plan!(@agency, rate_bps: 1000, minimum_cents: 200_000)
    p4_assign_plan!(agency: @agency, engagement: @ee[:engagement], plan:)

    CommissionDrawBalance.create!(agency: @agency, engagement: @ee[:engagement], balance_cents: 40_000)

    pp2 = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 1, 16), end_on: Date.new(2024, 1, 31), label: "P2")
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: pp2,
      period_start_on: pp2.start_on,
      period_end_on: pp2.end_on,
      commissionable_revenue_cents: 5_000_000,
      source_type: "manual"
    )

    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: nil)

    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    assert_equal 500_000, calc.calculated_commission_cents
    assert_equal 40_000, calc.draw_recovery_cents
    assert_equal 460_000, calc.gross_commission_pay_cents
    assert_equal 0, calc.ending_draw_balance_cents

    assert_equal 1, DrawBalanceEvent.where(engagement: @ee[:engagement], event_type: "recovery").count
  end

  test "contractor gets flat commission only with zero draw" do
    plan = p4_commission_plan!(@agency, name: "IC plan", rate_bps: 800, minimum_cents: nil)
    p4_assign_plan!(agency: @agency, engagement: @ic[:engagement], plan:)

    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      commissionable_revenue_cents: 1_000_000,
      source_type: "manual"
    )

    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: nil)

    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    assert_equal 80_000, calc.calculated_commission_cents
    assert_equal 80_000, calc.gross_commission_pay_cents
    assert_equal 0, calc.draw_added_cents
    assert_equal 0, calc.draw_recovery_cents
    assert_equal 0, calc.ending_draw_balance_cents
    assert_not CommissionDrawBalance.exists?(engagement_id: @ic[:engagement].id)
  end

  test "raises when no assignment effective on period" do
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: @pp,
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 100_000,
      source_type: "manual"
    )

    err = assert_raises(ArgumentError) do
      Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: nil)
    end
    assert_match(/No compensation plan assignment/, err.message)
  end

  test "raises when assignment has no commission rate" do
    plan = CompensationPlan.create!(
      agency: @agency,
      name: "Zero rate",
      plan_type: "salary_only",
      status: "active",
      default_commission_rate_bps: nil
    )
    p4_assign_plan!(agency: @agency, engagement: @ee[:engagement], plan:)

    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: @pp,
      period_start_on: @pp.start_on,
      period_end_on: @pp.end_on,
      commissionable_revenue_cents: 100_000,
      source_type: "manual"
    )

    err = assert_raises(ArgumentError) do
      Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: nil)
    end
    assert_match(/commission rate/i, err.message)
  end
end

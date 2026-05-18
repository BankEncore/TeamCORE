# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementPreviewLineTest < ActiveSupport::TestCase
  setup do
    @agency, @actor = p4_agency_user!
    @ic = p4_active_ic!(@agency)
    plan = p4_commission_plan!(@agency, name: "IC", rate_bps: 1000, minimum_cents: nil)
    p4_assign_plan!(agency: @agency, engagement: @ic[:engagement], plan:)

    @rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      commissionable_revenue_cents: 2_000_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: @rev, actor: @actor)
    @calc = CommissionCalculation.find_by!(revenue_input_id: @rev.id)
    @calc.update!(status: "finalized")

    @charge = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "technology_fee",
      status: "open",
      original_amount_cents: 50_000,
      open_balance_cents: 50_000,
      due_on: Date.new(2024, 1, 15)
    )

    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
  end

  test "preview defaults do not persist lines or recoveries" do
    lines_before = ContractorSettlementLine.count
    rec_before = ContractorChargeRecovery.count

    preview =
      Financials::ContractorSettlement::PreviewLine.call(
        run: @run,
        engagement: @ic[:engagement],
        include_future_due: false,
        manual_positive_cents: 0,
        manual_negative_cents: 0
      )

    assert_operator preview.computation.gross_commission_cents, :>, 0
    assert_equal lines_before, ContractorSettlementLine.count
    assert_equal rec_before, ContractorChargeRecovery.count
  end

  test "preview excludes settled calculations from defaults" do
    other = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
    Financials::ContractorSettlement::ComposeLine.call(
      run: other,
      engagement: @ic[:engagement],
      actor: @actor,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [],
      contractor_charge_ids: [],
      manual_positive: 0,
      manual_negative: 0
    )

    preview =
      Financials::ContractorSettlement::PreviewLine.call(
        run: @run,
        engagement: @ic[:engagement],
        manual_positive_cents: 0,
        manual_negative_cents: 0
      )

    assert_equal 0, preview.computation.gross_commission_cents
    assert_empty preview.selected_commission_calculation_ids
  end
end

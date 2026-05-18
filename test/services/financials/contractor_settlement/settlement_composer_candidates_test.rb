# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementSettlementComposerCandidatesTest < ActiveSupport::TestCase
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

    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
  end

  test "settled commission calculation ids excludes voided runs only" do
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

    settled =
      Financials::ContractorSettlement::SettlementComposerCandidates.settled_commission_calculation_ids(agency_id: @agency.id)
    assert_includes settled, @calc.id

    other.update!(status: "voided")
    settled2 =
      Financials::ContractorSettlement::SettlementComposerCandidates.settled_commission_calculation_ids(agency_id: @agency.id)
    assert_not_includes settled2, @calc.id
  end

  test "commission rows mark already settled as excluded" do
    Financials::ContractorSettlement::ComposeLine.call(
      run:
        ContractorSettlementRun.create!(
          agency: @agency,
          period_start_on: Date.new(2024, 1, 1),
          period_end_on: Date.new(2024, 1, 31),
          status: "draft"
        ),
      engagement: @ic[:engagement],
      actor: @actor,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [],
      contractor_charge_ids: [],
      manual_positive: 0,
      manual_negative: 0
    )

    rows = Financials::ContractorSettlement::SettlementComposerCandidates.commission_rows(run: @run, engagement: @ic[:engagement])
    row = rows.find { |r| r.calculation.id == @calc.id }
    assert_equal :already_on_run, row.exclusion_reason
    assert_equal false, row.default_checked
  end

  test "open charges ordered due_on nulls first then id" do
    c_late = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "technology_fee",
      status: "open",
      original_amount_cents: 100,
      open_balance_cents: 100,
      due_on: Date.new(2025, 6, 1)
    )
    c_nil = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "onboarding_fee",
      status: "open",
      original_amount_cents: 100,
      open_balance_cents: 100,
      due_on: nil
    )
    c_early = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "annual_renewal_fee",
      status: "open",
      original_amount_cents: 100,
      open_balance_cents: 100,
      due_on: Date.new(2024, 1, 5)
    )

    ordered =
      Financials::ContractorSettlement::SettlementComposerCandidates
        .ordered_open_charges(run: @run, engagement: @ic[:engagement])
        .pluck(:id)

    assert_equal [ c_nil.id, c_early.id, c_late.id ], ordered
  end
end

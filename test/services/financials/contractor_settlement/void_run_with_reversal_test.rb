# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementVoidRunWithReversalTest < ActiveSupport::TestCase
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
      original_amount_cents: 500_000,
      open_balance_cents: 500_000
    )

    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
  end

  def compose_line!(charge_ids: [ @charge.id ], charge_map: nil)
    Financials::ContractorSettlement::ComposeLine.call(
      run: @run,
      engagement: @ic[:engagement],
      actor: @actor,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [ @calc.id ],
      contractor_charge_ids: charge_ids,
      manual_positive: 0,
      manual_negative: 0,
      charge_deductions_cents_by_id: charge_map
    )
  end

  test "void restores balance and creates reversal rows while keeping originals" do
    line = compose_line!
    deduction = ContractorChargeRecovery.find_by!(contractor_settlement_line: line, source_type: "settlement_deduction")

    Financials::ContractorSettlement::VoidRunWithReversal.call(
      run: @run,
      actor: @actor,
      reason: "Entered wrong period"
    )

    @run.reload
    @charge.reload
    assert_equal "voided", @run.status
    assert_equal 500_000, @charge.open_balance_cents
    assert_equal "open", @charge.status

    assert ContractorSettlementLine.exists?(line.id)
    assert_equal 1, line.contractor_settlement_line_commission_calculations.count
    assert deduction.reload

    reversal = ContractorChargeRecovery.find_by!(
      contractor_settlement_line: line,
      source_type: "settlement_deduction_reversal"
    )
    assert_equal deduction.amount_cents, reversal.amount_cents
    assert_includes reversal.notes, "original recovery ##{deduction.id}"

    settled = Financials::ContractorSettlement::SettlementComposerCandidates
      .settled_commission_calculation_ids(agency_id: @agency.id)
    refute_includes settled, @calc.id
  end

  test "void twice is rejected" do
    compose_line!
    Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "first")

    err = assert_raises(Financials::ContractorSettlement::VoidRunWithReversal::Error) do
      Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "second")
    end
    assert_match(/already voided/i, err.message)
  end

  test "blank reason is rejected" do
    compose_line!
    err = assert_raises(Financials::ContractorSettlement::VoidRunWithReversal::Error) do
      Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "  ")
    end
    assert_match(/reason is required/i, err.message)
  end

  test "paid_recorded run cannot be voided" do
    compose_line!
    @run.update!(status: "paid_recorded")

    err = assert_raises(Financials::ContractorSettlement::VoidRunWithReversal::Error) do
      Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "too late")
    end
    assert_match(/cannot be voided/i, err.message)
  end

  test "run with export cannot be voided" do
    compose_line!
    @run.update!(status: "calculated")
    ContractorSettlementExport.create!(
      contractor_settlement_run: @run,
      file_format: "csv",
      is_final: false,
      exported_by: @actor
    )

    err = assert_raises(Financials::ContractorSettlement::VoidRunWithReversal::Error) do
      Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "oops")
    end
    assert_match(/exports cannot be voided/i, err.message)
  end

  test "finalized unexported run can be voided" do
    compose_line!
    @run.update!(status: "finalized")

    Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "wrong totals")
    assert_equal "voided", @run.reload.status
  end

  test "closed charge reopens when balance restored" do
    small_charge = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "technology_fee",
      status: "open",
      original_amount_cents: 50_000,
      open_balance_cents: 50_000
    )

    compose_line!(charge_ids: [ small_charge.id ])
    small_charge.reload
    assert_equal "closed", small_charge.status
    assert_equal 0, small_charge.open_balance_cents

    Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "reopen")
    small_charge.reload
    assert_equal "open", small_charge.status
    assert_equal 50_000, small_charge.open_balance_cents
  end

  test "partial deduction charge stays open with restored balance" do
    compose_line!(
      charge_map: { @charge.id.to_s => 100_000 }
    )
    @charge.reload
    assert_equal "open", @charge.status
    assert_equal 400_000, @charge.open_balance_cents

    Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "undo partial")
    @charge.reload
    assert_equal "open", @charge.status
    assert_equal 500_000, @charge.open_balance_cents
  end

  test "waived charge after deduction blocks void" do
    compose_line!(charge_map: { @charge.id.to_s => 100_000 })
    @charge.update!(status: "waived")

    err = assert_raises(Financials::ContractorSettlement::VoidRunWithReversal::Error) do
      Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "blocked")
    end
    assert_match(/waived/i, err.message)
    assert_equal "draft", @run.reload.status
  end

  test "empty run can still be voided without lines" do
    Financials::ContractorSettlement::VoidRunWithReversal.call(run: @run, actor: @actor, reason: "cancel empty run")
    assert_equal "voided", @run.reload.status
  end
end

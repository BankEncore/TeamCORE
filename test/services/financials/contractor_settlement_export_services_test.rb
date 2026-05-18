# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementExportServicesTest < ActiveSupport::TestCase
  setup do
    @agency, @actor = p4_agency_user!
    @ic = p4_active_ic!(@agency)
    plan = p4_commission_plan!(@agency, name: "IC-exp", rate_bps: 1000, minimum_cents: nil)
    p4_assign_plan!(agency: @agency, engagement: @ic[:engagement], plan:)

    @rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      period_start_on: Date.new(2025, 9, 1),
      period_end_on: Date.new(2025, 9, 30),
      commissionable_revenue_cents: 1_000_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: @rev, actor: @actor)
    CommissionCalculation.find_by!(revenue_input_id: @rev.id).update!(status: "finalized")

    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2025, 9, 1),
      period_end_on: Date.new(2025, 9, 30),
      status: "draft"
    )

    Financials::ContractorSettlement::ComposeLine.call(
      run: @run,
      engagement: @ic[:engagement],
      actor: @actor,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [],
      contractor_charge_ids: [],
      manual_positive: 0,
      manual_negative: 0
    )
    @run.reload.update!(status: "calculated")
  end

  test "draft settlement export attaches file and logs event" do
    export = Financials::ContractorSettlement::GenerateDraftSettlementExportService.call(
      run: @run.reload,
      actor: @actor,
      file_format: "csv"
    )
    assert export.export_file.attached?
    assert_not export.is_final?
    assert ContractorSettlementRunEvent.exists?(contractor_settlement_run_id: @run.id, event_type: "draft_exported")
  end

  test "final settlement export requires finalized status" do
    err = assert_raises(Financials::ContractorSettlement::GenerateFinalSettlementExportService::Error) do
      Financials::ContractorSettlement::GenerateFinalSettlementExportService.call(run: @run.reload, actor: @actor, file_format: "csv")
    end
    assert_match(/finalized/i, err.message)
  end

  test "final settlement export after finalize" do
    @run.update!(status: "finalized")
    ContractorSettlementRunEvent.create!(
      contractor_settlement_run: @run,
      event_type: "finalized",
      actor: @actor,
      reason: "test"
    )

    export = Financials::ContractorSettlement::GenerateFinalSettlementExportService.call(
      run: @run.reload,
      actor: @actor,
      file_format: "csv"
    )
    assert export.is_final?
    assert export.export_file.attached?
    assert ContractorSettlementRunEvent.exists?(contractor_settlement_run_id: @run.id, event_type: "final_exported")
  end
end

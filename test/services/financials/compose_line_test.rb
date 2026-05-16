# frozen_string_literal: true

require "test_helper"

class FinancialsContractorSettlementComposeLineTest < ActiveSupport::TestCase
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

  test "creates line with joins and caps charge deductions so net is non negative" do
    line = Financials::ContractorSettlement::ComposeLine.call(
      run: @run,
      engagement: @ic[:engagement],
      actor: @actor,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [],
      contractor_charge_ids: [ @charge.id ],
      manual_positive: 0,
      manual_negative: 0
    )

    assert_equal 200_000, line.gross_commission_cents
    assert_equal 200_000, line.charge_deductions_cents
    assert_equal 0, line.net_settlement_cents

    assert_equal 1, line.contractor_settlement_line_revenue_inputs.count
    assert_equal 1, line.contractor_settlement_line_commission_calculations.count
    assert_equal 1, ContractorChargeRecovery.where(contractor_settlement_line: line).count

    @charge.reload
    assert_equal 300_000, @charge.open_balance_cents
  end

  test "rejects engagement that cannot settle" do
    ee = p4_active_employee!(@agency)

    err = assert_raises(ArgumentError) do
      Financials::ContractorSettlement::ComposeLine.call(
        run: @run,
        engagement: ee[:engagement],
        actor: @actor,
        revenue_input_ids: [],
        commission_calculation_ids: [],
        contractor_charge_ids: []
      )
    end
    assert_match(/not eligible|Engagement not eligible/i, err.message)
  end

  test "rejects finalized run" do
    @run.update!(status: "finalized")

    err = assert_raises(ArgumentError) do
      Financials::ContractorSettlement::ComposeLine.call(
        run: @run,
        engagement: @ic[:engagement],
        actor: @actor,
        revenue_input_ids: [ @rev.id ],
        commission_calculation_ids: [],
        contractor_charge_ids: []
      )
    end
    assert_match(/draft/i, err.message)
  end
end

# frozen_string_literal: true

require "test_helper"

class Team360ProfileAssemblerPhase4Test < ActiveSupport::TestCase
  test "phase4_financial reflects compensation and last settlement for focused contractor" do
    agency, user = p4_agency_user!
    ic = p4_active_ic!(agency)
    plan = p4_commission_plan!(agency, name: "IC Plan", rate_bps: 900, minimum_cents: nil)
    p4_assign_plan!(agency:, engagement: ic[:engagement], plan:)

    run = ContractorSettlementRun.create!(
      agency:,
      period_start_on: Date.new(2024, 1, 1),
      period_end_on: Date.new(2024, 1, 31),
      status: "draft"
    )
    ContractorSettlementLine.create!(
      contractor_settlement_run: run,
      agency:,
      engagement: ic[:engagement],
      gross_commission_cents: 50_000,
      charge_deductions_cents: 10_000,
      manual_adjustment_positive_cents: 0,
      manual_adjustment_negative_cents: 0,
      net_settlement_cents: 40_000
    )

    snapshot = Team360::ProfileAssembler.new(
      team_member: ic[:team_member],
      agency:,
      current_user: user,
      focused_engagement_id: ic[:engagement].id
    ).call

    p4 = snapshot.phase4_financial
    assert_equal ic[:engagement].id, p4[:focused_engagement_id]
    assert_equal "IC Plan", p4[:assignment_summary][:plan_name]
    assert_nil p4[:draw_balance_cents]
    assert_equal 40_000, p4[:last_settlement][:net_cents]
    assert_equal run.status, p4[:last_settlement][:status]
  end

  test "phase4_financial includes draw balance for focused employee" do
    agency, = p4_agency_user!
    ee = p4_active_employee!(agency)
    plan = p4_commission_plan!(agency, minimum_cents: 100_000)
    p4_assign_plan!(agency:, engagement: ee[:engagement], plan:)
    CommissionDrawBalance.create!(agency:, engagement: ee[:engagement], balance_cents: 25_000)

    snapshot = Team360::ProfileAssembler.new(
      team_member: ee[:team_member],
      agency:,
      focused_engagement_id: ee[:engagement].id
    ).call

    p4 = snapshot.phase4_financial
    assert_equal 25_000, p4[:draw_balance_cents]
    assert_nil p4[:last_settlement]
  end
end

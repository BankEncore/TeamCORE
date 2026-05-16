# frozen_string_literal: true

require "test_helper"

class Team360ProfileAssemblerWorkforceFinancialTest < ActiveSupport::TestCase
  test "workforce_financial reflects compensation and last settlement for focused contractor" do
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

    fin = snapshot.workforce_financial
    assert_equal ic[:engagement].id, fin[:focused_engagement_id]
    assert_equal "IC Plan", fin[:assignment_summary][:plan_name]
    assert_nil fin[:draw_balance_cents]
    assert_equal 40_000, fin[:last_settlement][:net_cents]
    assert_equal run.status, fin[:last_settlement][:status]
  end

  test "workforce_financial includes draw balance for focused employee" do
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

    fin = snapshot.workforce_financial
    assert_equal 25_000, fin[:draw_balance_cents]
    assert_nil fin[:last_settlement]
  end

  test "workforce_financial hides draw when user denies Team360 draw visibility" do
    agency, user = p4_agency_user!
    ee = p4_active_employee!(agency)
    plan = p4_commission_plan!(agency, minimum_cents: 100_000)
    p4_assign_plan!(agency:, engagement: ee[:engagement], plan:)
    CommissionDrawBalance.create!(agency:, engagement: ee[:engagement], balance_cents: 25_000)

    def user.team360_show_employee_draw_balance?
      false
    end

    snapshot = Team360::ProfileAssembler.new(
      team_member: ee[:team_member],
      agency:,
      current_user: user,
      focused_engagement_id: ee[:engagement].id
    ).call

    assert_nil snapshot.workforce_financial[:draw_balance_cents]
  end

  test "workforce_financial contractor payload includes admin links and past-due charges" do
    agency, user = p4_agency_user!
    ic = p4_active_ic!(agency)
    plan = p4_commission_plan!(agency, name: "IC Plan", rate_bps: 900, minimum_cents: nil)
    p4_assign_plan!(agency:, engagement: ic[:engagement], plan:)

    ContractorCharge.create!(
      agency:,
      engagement: ic[:engagement],
      charge_type: "technology_fee",
      status: "open",
      original_amount_cents: 5_000,
      open_balance_cents: 5_000,
      due_on: Date.new(2020, 1, 1)
    )

    snapshot = Team360::ProfileAssembler.new(
      team_member: ic[:team_member],
      agency:,
      current_user: user,
      as_of_date: Date.new(2024, 6, 1),
      focused_engagement_id: ic[:engagement].id
    ).call

    fin = snapshot.workforce_financial
    assert fin[:admin_links][:revenue_inputs].present?
    assert fin[:admin_links][:commission_calculations].present?
    assert fin[:admin_links][:contractor_charges].present?
    assert_operator fin[:contractor_charges][:past_due_count], :>, 0
  end
end

# frozen_string_literal: true

require "test_helper"
require "stringio"

class AdminPhase4FinancialsTest < ActionDispatch::IntegrationTest
  setup do
    @agency, @user = p4_agency_user!
    @ee = p4_active_employee!(@agency)
    @ic = p4_active_ic!(@agency)
    @plan = p4_commission_plan!(@agency, rate_bps: 1000, minimum_cents: 200_000)
    p4_assign_plan!(agency: @agency, engagement: @ee[:engagement], plan: @plan)

    post login_path, params: { email: @user.email, password: Phase4TestHelper::PASSWORD }
    follow_redirect!
  end

  test "revenue update blocked when commission finalized" do
    pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 11, 1), end_on: Date.new(2024, 11, 15), label: "Nov-1")
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: pp,
      period_start_on: pp.start_on,
      period_end_on: pp.end_on,
      commissionable_revenue_cents: 800_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: @user)
    CommissionCalculation.find_by!(revenue_input_id: rev.id).update!(status: "finalized")

    patch admin_engagement_revenue_input_path(@ee[:engagement], rev), params: {
      revenue_input: {
        pay_period_id: pp.id,
        period_start_on: "2024-11-01",
        period_end_on: "2024-11-15",
        commissionable_revenue_money: "8000.00",
        source_type: "manual",
        notes: "try edit"
      }
    }
    follow_redirect!
    assert_match(/locked/i, flash[:alert].to_s)
  end

  test "settlement run mark paid and void" do
    run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2024, 12, 1),
      period_end_on: Date.new(2024, 12, 31),
      status: "finalized"
    )
    post mark_paid_admin_contractor_settlement_run_path(run), params: { reason: "ACH" }
    assert_redirected_to admin_contractor_settlement_run_path(run)
    assert_equal "paid_recorded", run.reload.status
    assert ContractorSettlementRunEvent.exists?(contractor_settlement_run_id: run.id, event_type: "payment_recorded")

    run2 = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2025, 1, 1),
      period_end_on: Date.new(2025, 1, 31),
      status: "finalized"
    )
    post void_admin_contractor_settlement_run_path(run2), params: { reason: "duplicate" }
    assert_redirected_to admin_contractor_settlement_run_path(run2)
    assert_equal "voided", run2.reload.status
    assert ContractorSettlementRunEvent.exists?(contractor_settlement_run_id: run2.id, event_type: "voided")
  end

  test "pay periods index and create" do
    get admin_pay_periods_path
    assert_response :success

    assert_difference -> { PayPeriod.where(agency_id: @agency.id).count }, +1 do
      post admin_pay_periods_path, params: {
        pay_period: {
          label: "Adm P4 PP",
          start_on: "2024-06-01",
          end_on: "2024-06-15"
        }
      }
    end
    assert_redirected_to %r{/admin/pay_periods/\d+}
  end

  test "compensation plans index and create" do
    get admin_compensation_plans_path
    assert_response :success

    assert_difference -> { CompensationPlan.where(agency_id: @agency.id).count }, +1 do
      post admin_compensation_plans_path, params: {
        compensation_plan: {
          name: "Adm commission",
          plan_type: "commission_only",
          status: "active",
          default_commission_rate_percent: "5.00"
        }
      }
    end
    assert_response :redirect
  end

  test "employee revenue create and calculate commission redirects" do
    pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 7, 1), end_on: Date.new(2024, 7, 15), label: "Jul-1")

    assert_difference -> { @ee[:engagement].revenue_inputs.count }, +1 do
      post admin_engagement_revenue_inputs_path(@ee[:engagement]), params: {
        revenue_input: {
          pay_period_id: pp.id,
          period_start_on: "2024-07-01",
          period_end_on: "2024-07-15",
          commissionable_revenue_money: "20000.00",
          source_type: "manual",
          notes: "adm test"
        }
      }
    end
    assert_redirected_to admin_engagement_revenue_inputs_path(@ee[:engagement])

    rev = @ee[:engagement].revenue_inputs.order(:id).last
    post calculate_commission_admin_engagement_revenue_input_path(@ee[:engagement], rev)
    assert_redirected_to admin_engagement_commission_calculations_path(@ee[:engagement])
    assert CommissionCalculation.exists?(revenue_input_id: rev.id)
  end

  test "admin finalizes draft commission calculation" do
    pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 7, 16), end_on: Date.new(2024, 7, 31), label: "Jul-2")
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: pp,
      period_start_on: pp.start_on,
      period_end_on: pp.end_on,
      commissionable_revenue_cents: 500_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: @user)
    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    assert_equal "draft", calc.status

    post finalize_admin_engagement_commission_calculation_path(@ee[:engagement], calc)
    assert_redirected_to admin_engagement_commission_calculations_path(@ee[:engagement])
    assert_equal "finalized", calc.reload.status
  end

  test "admin cannot re-finalize commission calculation" do
    pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 7, 20), end_on: Date.new(2024, 7, 31), label: "Jul-2b")
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: pp,
      period_start_on: pp.start_on,
      period_end_on: pp.end_on,
      commissionable_revenue_cents: 400_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: @user)
    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    post finalize_admin_engagement_commission_calculation_path(@ee[:engagement], calc)
    assert_equal "finalized", calc.reload.status

    post finalize_admin_engagement_commission_calculation_path(@ee[:engagement], calc)
    follow_redirect!
    assert_match(/draft/i, flash[:alert].to_s)
  end

  test "calculate commission blocked after admin finalizes" do
    pp = PayPeriod.create!(agency: @agency, start_on: Date.new(2024, 7, 22), end_on: Date.new(2024, 7, 31), label: "Jul-2c")
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      pay_period: pp,
      period_start_on: pp.start_on,
      period_end_on: pp.end_on,
      commissionable_revenue_cents: 300_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: @user)
    calc = CommissionCalculation.find_by!(revenue_input_id: rev.id)
    post finalize_admin_engagement_commission_calculation_path(@ee[:engagement], calc)
    assert_equal "finalized", calc.reload.status

    post calculate_commission_admin_engagement_revenue_input_path(@ee[:engagement], rev)
    follow_redirect!
    assert_match(/locked/i, flash[:alert].to_s)
  end

  test "revenue csv import" do
    body = <<~CSV
      period_start_on,period_end_on,commissionable_revenue,source_type
      2024-08-01,2024-08-15,999.99,imported_csv
    CSV
    file = Rack::Test::UploadedFile.new(StringIO.new(body), "text/csv", original_filename: "rev.csv")

    assert_difference -> { @ic[:engagement].revenue_inputs.count }, +1 do
      post import_csv_admin_engagement_revenue_inputs_path(@ic[:engagement]), params: { csv_file: file }
    end
    assert_redirected_to admin_engagement_revenue_inputs_path(@ic[:engagement])
    ri = @ic[:engagement].revenue_inputs.order(:id).last
    assert_equal 99_999, ri.commissionable_revenue_cents
    assert_equal "imported_csv", ri.source_type
  end

  test "contractor charge create for IC" do
    assert_difference -> { @ic[:engagement].contractor_charges.count }, +1 do
      post admin_engagement_contractor_charges_path(@ic[:engagement]), params: {
        contractor_charge: {
          charge_type: "technology_fee",
          status: "open",
          original_amount_money: "50.00",
          open_balance_money: "50.00"
        }
      }
    end
    assert_response :redirect
  end

  test "contractor charge rejected for subcontractor" do
    sub = p4_active_subcontractor!(@agency)

    assert_no_difference -> { ContractorCharge.count } do
      post admin_engagement_contractor_charges_path(sub[:engagement]), params: {
        contractor_charge: {
          charge_type: "onboarding_fee",
          status: "open",
          original_amount_money: "10.00",
          open_balance_money: "10.00"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "settlement run create finalize and compose line" do
    plan_ic = p4_commission_plan!(@agency, name: "IC c", rate_bps: 1000, minimum_cents: nil)
    p4_assign_plan!(agency: @agency, engagement: @ic[:engagement], plan: plan_ic)
    rev = RevenueInput.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      period_start_on: Date.new(2024, 9, 1),
      period_end_on: Date.new(2024, 9, 30),
      commissionable_revenue_cents: 500_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: rev, actor: @user)

    charge = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "annual_renewal_fee",
      status: "open",
      original_amount_cents: 10_000,
      open_balance_cents: 10_000
    )

    assert_difference -> { ContractorSettlementRun.where(agency_id: @agency.id).count }, +1 do
      post admin_contractor_settlement_runs_path, params: {
        contractor_settlement_run: {
          period_start_on: "2024-09-01",
          period_end_on: "2024-09-30"
        }
      }
    end
    run = ContractorSettlementRun.where(agency_id: @agency.id).order(:id).last

    post compose_line_admin_contractor_settlement_run_path(run), params: {
      engagement_id: @ic[:engagement].id,
      revenue_input_ids: rev.id.to_s,
      commission_calculation_ids: "",
      contractor_charge_ids: charge.id.to_s
    }
    assert_redirected_to admin_contractor_settlement_run_path(run)
    assert run.contractor_settlement_lines.exists?(engagement_id: @ic[:engagement].id)

    post finalize_admin_contractor_settlement_run_path(run)
    assert_redirected_to admin_contractor_settlement_run_path(run)
    assert_equal "finalized", run.reload.status
  end

  test "team360 includes workforce financial panel copy for focused engagement" do
    get admin_team_member_team360_path(@ic[:team_member], params: { engagement_id: @ic[:engagement].id })
    assert_response :success
    assert_includes @response.body, "Compensation"
  end
end

# frozen_string_literal: true

require "test_helper"

class AdminContractorSettlementComposeIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "SettleCo", code: "st#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "st#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)

    ic = p4_active_ic!(@agency)
    @engagement = ic[:engagement]
    plan = p4_commission_plan!(@agency, name: "IC", rate_bps: 1000, minimum_cents: nil)
    p4_assign_plan!(agency: @agency, engagement: @engagement, plan:)

    @rev = RevenueInput.create!(
      agency: @agency,
      engagement: @engagement,
      period_start_on: Date.new(2025, 3, 1),
      period_end_on: Date.new(2025, 3, 31),
      commissionable_revenue_cents: 500_000,
      source_type: "manual"
    )
    Financials::ApplyCommissionAndDraw.call(revenue_input: @rev, actor: @user)
    CommissionCalculation.find_by!(revenue_input_id: @rev.id).update!(status: "finalized")

    @run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2025, 3, 1),
      period_end_on: Date.new(2025, 3, 31),
      status: "draft"
    )

    post login_path, params: { email: @user.email, password: "password1234" }
    follow_redirect!
  end

  test "void is blocked after composed lines exist" do
    Financials::ContractorSettlement::ComposeLine.call(
      run: @run,
      engagement: @engagement,
      actor: @user,
      revenue_input_ids: [ @rev.id ],
      commission_calculation_ids: [],
      contractor_charge_ids: [],
      manual_positive: 0,
      manual_negative: 0
    )

    post void_admin_contractor_settlement_run_path(@run), params: { reason: "try void" }
    assert_redirected_to admin_contractor_settlement_run_path(@run)
    follow_redirect!
    assert_match(/cannot be voided|reversal/i, flash[:alert].to_s)
  end

  test "line composer includes authenticity token when forgery protection is enabled" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      get line_composer_admin_contractor_settlement_run_path(@run, engagement_id: @engagement.id)
      assert_response :success
      assert_includes @response.body, 'name="authenticity_token"'
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end

  test "line composer loads for draft run" do
    get line_composer_admin_contractor_settlement_run_path(@run, engagement_id: @engagement.id)
    assert_response :success
    assert_includes @response.body, "Compose settlement line"
    assert_includes @response.body, preview_settlement_line_admin_contractor_settlement_run_path(@run)
  end

  test "compose line accepts session CSRF token when forgery protection is enabled" do
    calc = CommissionCalculation.find_by!(revenue_input_id: @rev.id)
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      get line_composer_admin_contractor_settlement_run_path(@run, engagement_id: @engagement.id)
      assert_response :success
      token = @response.body[/name="authenticity_token" value="([^"]+)"/, 1]
      assert token.present?, "expected authenticity_token in line composer form"

      post compose_line_admin_contractor_settlement_run_path(@run),
        params: {
          authenticity_token: token,
          engagement_id: @engagement.id,
          commission_calculation_ids: [ calc.id ],
          contractor_charge_ids: [],
          manual_positive_money: "0.00",
          manual_negative_money: "0.00",
          commit: "Compose settlement line"
        }
      assert_redirected_to admin_contractor_settlement_run_path(@run)
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end

  test "preview settlement line round-trips selections" do
    calc = CommissionCalculation.find_by!(revenue_input_id: @rev.id)

    post preview_settlement_line_admin_contractor_settlement_run_path(@run),
      params: {
        engagement_id: @engagement.id,
        commission_calculation_ids: [ calc.id ],
        contractor_charge_ids: [],
        manual_positive_money: "0.00",
        manual_negative_money: "0.00"
      }

    assert_response :success
    assert_includes @response.body, "Preview totals"
    assert_includes @response.body, "commission_calc_#{calc.id}"
  end
end

# frozen_string_literal: true

require "test_helper"

class AdminFormCsrfTokensTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "CsrfCo", code: "cs#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "cs#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)

    ic = p4_active_ic!(@agency)
    @engagement = ic[:engagement]

    post login_path, params: { email: @user.email, password: "password1234" }
    follow_redirect!
  end

  test "mutating admin forms include authenticity token when forgery protection is enabled" do
    run = ContractorSettlementRun.create!(
      agency: @agency,
      period_start_on: Date.new(2025, 3, 1),
      period_end_on: Date.new(2025, 3, 31),
      status: "draft"
    )

    pages = [
      new_admin_engagement_revenue_input_path(@engagement),
      admin_engagement_revenue_inputs_path(@engagement),
      line_composer_admin_contractor_settlement_run_path(run, engagement_id: @engagement.id),
      admin_contractor_settlement_run_path(run)
    ]

    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    begin
      pages.each do |path|
        get path
        assert_response :success, "expected success for #{path}"
        assert_includes @response.body, 'name="authenticity_token"', "missing token on #{path}"
      end
    ensure
      ActionController::Base.allow_forgery_protection = previous
    end
  end
end

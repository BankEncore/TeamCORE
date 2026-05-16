# frozen_string_literal: true

require "test_helper"

class AdminEngagementsContractorClassificationSupportTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "TC09 Panel Agency", code: "tc9#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "tc09#{SecureRandom.hex(6)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    party = Party.create!(agency: @agency, party_type: "person", display_name: "IC Panel")
    PersonProfile.create!(party: party, first_name: "IC", last_name: "Panel")
    party.reload

    @team_member = TeamMember.create!(agency: @agency, party: party)
    @ic_engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "individual_contractor",
      status: "pending"
    )
    @ic_engagement.update!(status: "active", start_on: Date.new(2026, 2, 1))

    emp_party = Party.create!(agency: @agency, party_type: "person", display_name: "Emp Panel")
    PersonProfile.create!(party: emp_party, first_name: "Emp", last_name: "Panel")
    emp_party.reload
    emp_tm = TeamMember.create!(agency: @agency, party: emp_party)
    @employee_engagement = Engagement.create!(
      agency: @agency,
      team_member: emp_tm,
      relationship_type: "employee",
      status: "pending"
    )
    @employee_engagement.update!(status: "active", start_on: Date.new(2026, 2, 1))

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "contractor engagement show includes classification support panel" do
    get admin_engagement_path(@ic_engagement)
    assert_response :success
    assert_select "#contractor-classification-support"
    assert_includes response.body, "Classification support status"
  end

  test "employee engagement show omits classification support panel" do
    get admin_engagement_path(@employee_engagement)
    assert_response :success
    assert_select "#contractor-classification-support", count: 0
  end
end

# frozen_string_literal: true

require "test_helper"

class AdminTeam360NextActionsIntegrationTest < ActionDispatch::IntegrationTest
  test "team360 shows next actions panel when placement gap exists" do
    agency = Agency.create!(name: "T360NBA", code: "t3#{SecureRandom.hex(4)}")
    user = User.create!(
      email: "t360nba#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: user, agency: agency)

    party = Party.create!(agency: agency, party_type: "person", display_name: "Pat360", status: "active")
    PersonProfile.create!(party: party, first_name: "Pat", last_name: "Lee")
    party.reload
    tm = TeamMember.create!(agency: agency, party: party, status: "active")
    eng = Engagement.create!(
      agency: agency,
      team_member: tm,
      relationship_type: "employee",
      title: "Rep",
      status: "active",
      start_on: Date.current
    )

    post login_path, params: { email: user.email, password: "password1234" }
    follow_redirect!

    get admin_team_member_team360_path(tm, params: { engagement_id: eng.id })
    assert_response :success
    assert_includes @response.body, "Next actions"
    assert_includes @response.body, "Current placement"
    assert_includes @response.body, "/admin/engagements/#{eng.id}/placements/new"
  end
end

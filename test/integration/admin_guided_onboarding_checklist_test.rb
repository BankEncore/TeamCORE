# frozen_string_literal: true

require "test_helper"

class AdminGuidedOnboardingChecklistIntegrationTest < ActionDispatch::IntegrationTest
  test "guided employee shows checklist panel and placement gap CTA when engaged" do
    agency = Agency.create!(name: "GOINT", code: "gi#{SecureRandom.hex(4)}")
    user = User.create!(
      email: "goguide#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: user, agency: agency)

    party = Party.create!(agency: agency, party_type: "person", display_name: "Guide Pat", status: "active")
    PersonProfile.create!(party: party, first_name: "Guide", last_name: "Pat")
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

    get admin_guided_employee_path(params: { party_id: party.id })
    assert_response :success
    assert_includes @response.body, 'id="guided-onboarding-checklist"'
    assert_includes @response.body, "Setup checklist"
    assert_includes @response.body, "Current placement"
    assert_includes @response.body, "/admin/engagements/#{eng.id}/placements/new"
  end
end

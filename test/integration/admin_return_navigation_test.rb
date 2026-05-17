# frozen_string_literal: true

require "test_helper"

class AdminReturnNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "RetNav", code: "rn#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "rn#{SecureRandom.hex(4)}@ex.com",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Alex", status: "active")
    PersonProfile.create!(party: @party, first_name: "Alex", last_name: "R")
    @party.reload

    @tm = TeamMember.create!(agency: @agency, party: @party, status: "active")
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "employee",
      title: "Role",
      status: "draft"
    )

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "engagement update ignores open redirect return_to" do
    patch admin_engagement_path(@engagement),
      params: {
        engagement: { status: "draft", relationship_type: "employee", title: "Updated A" },
        return_to: "https://evil.example/phish",
        team360_return_to: "//evil.example/phish"
      }
    assert_redirected_to admin_engagement_path(@engagement)
  end

  test "engagement update redirects to team360_return_to when safe" do
    target = admin_team_member_team360_path(@tm, engagement_id: @engagement.id)
    patch admin_engagement_path(@engagement),
      params: {
        engagement: { status: "draft", relationship_type: "employee", title: "Updated B" },
        team360_return_to: target
      }
    assert_redirected_to target
  end

  test "engagement update allows return_to with admin query string" do
    target = admin_engagements_path(status: "draft")
    patch admin_engagement_path(@engagement),
      params: {
        engagement: { status: "draft", relationship_type: "employee", title: "Updated C" },
        return_to: target
      }
    assert_redirected_to target
  end

  test "edit form does not echo unsafe return_to into hidden field" do
    get edit_admin_engagement_path(@engagement, return_to: "https://evil.example/nope")
    assert_response :success
    assert_no_match(/evil\.example/, @response.body)
  end
end

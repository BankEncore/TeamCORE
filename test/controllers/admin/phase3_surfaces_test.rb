# frozen_string_literal: true

require "test_helper"

class Admin::Team360ControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "T360", code: "t#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "u#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)

    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Lee")
    @party.reload
    @tm = TeamMember.create!(agency: @agency, party: @party)
  end

  test "requires sign-in" do
    get admin_team_member_team360_path(@tm)
    assert_redirected_to login_path
  end

  test "shows team360 when signed in" do
    post login_path, params: { email: @user.email, password: "password1234" }
    assert_response :redirect
    follow_redirect!

    get admin_team_member_team360_path(@tm)
    assert_response :success
    assert_includes @response.body, "Team360"
  end
end

class Admin::Reports::HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Rep", code: "r#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "rep#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)
  end

  test "reports hub loads" do
    post login_path, params: { email: @user.email, password: "password1234" }
    follow_redirect!

    get admin_reports_root_path
    assert_response :success
    assert_includes @response.body, "Team member roster"
  end
end

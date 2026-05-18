# frozen_string_literal: true

require "test_helper"

class AdminWorkspaceHubsTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "HubCo", code: "hub#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "hub#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)

    post login_path, params: { email: @user.email, password: "password1234" }
    follow_redirect!
  end

  test "workspace hubs load when agency context is implicit (single agency)" do
    get admin_people_hub_path
    assert_response :success
    assert_includes @response.body, "People"

    get admin_onboarding_hub_path
    assert_response :success

    get admin_documents_hub_path
    assert_response :success

    get admin_payroll_settlement_hub_path
    assert_response :success

    get admin_time_leave_hub_path
    assert_response :success

    get admin_configuration_hub_path
    assert_response :success
  end

  test "header search submits to search index" do
    get admin_root_path
    assert_response :success
    assert_select "form[action='#{admin_search_path}'][method=get]" do
      assert_select "input[name=q]"
    end

    get admin_search_path, params: { q: "zz" }
    assert_response :success
  end

  test "section nav lists workspace hubs and omits Reference CRUD links" do
    get admin_root_path
    assert_response :success

    assert_select "nav.tc-section-nav" do
      assert_select "a[href='#{admin_people_hub_path}']", text: "People"
      assert_select "a[href='#{admin_onboarding_hub_path}']", text: "Onboarding"
      assert_select "a[href='#{admin_reports_root_path}']", text: "Reports"

      assert_select "a[href='#{admin_parties_path}']", count: 0
      assert_select "a[href='#{admin_engagements_path}']", count: 0
      assert_select "a[href='#{admin_document_types_path}']", count: 0
    end
  end

  test "payroll settlement hub links contractor charges" do
    get admin_payroll_settlement_hub_path
    assert_response :success
    assert_select "a[href='#{admin_contractor_charges_path}']", text: "Contractor charges"
  end

  test "search lists team members section before parties section when both hit" do
    party = Party.create!(agency: @agency, party_type: "person", display_name: "HubSearchUnique", status: "active")
    PersonProfile.create!(party: party, first_name: "H", last_name: "U")
    TeamMember.create!(agency: @agency, party: party)

    get admin_search_path, params: { q: "HubSearch" }
    assert_response :success
    body = @response.body
    tm_heading = body.index("tc-panel__title\">Team members</div>")
    parties_heading = body.index("tc-panel__title\">Parties</div>")
    assert tm_heading && parties_heading
    assert_operator tm_heading, :<, parties_heading
  end
end

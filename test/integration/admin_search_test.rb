# frozen_string_literal: true

require "test_helper"

class AdminSearchTest < ActionDispatch::IntegrationTest
  setup do
    @agency_a = Agency.create!(name: "SA", code: "sa#{SecureRandom.hex(4)}")
    @agency_b = Agency.create!(name: "SB", code: "sb#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "sr#{SecureRandom.hex(4)}@ex.com",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency_a)
    UserAgency.create!(user: @user, agency: @agency_b)

    @party_a = Party.create!(agency: @agency_a, party_type: "person", display_name: "UniqueAlphaName", status: "active")
    PersonProfile.create!(party: @party_a, first_name: "U", last_name: "A")
    @party_b = Party.create!(agency: @agency_b, party_type: "person", display_name: "UniqueBetaName", status: "active")
    PersonProfile.create!(party: @party_b, first_name: "U", last_name: "B")

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
    patch admin_agency_context_path, params: { agency_id: @agency_a.id, return_to: admin_root_path }
    follow_redirect!
  end

  test "search returns only current agency parties" do
    get admin_search_path, params: { q: "Unique" }
    assert_response :success
    assert_includes @response.body, "UniqueAlphaName"
    assert_not_includes @response.body, "UniqueBetaName"
  end
end

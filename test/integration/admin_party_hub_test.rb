# frozen_string_literal: true

require "test_helper"

class AdminPartyHubTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Hub", code: "hub#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "hub#{SecureRandom.hex(4)}@ex.com",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Jane", status: "active")
    PersonProfile.create!(party: @party, first_name: "Jane", last_name: "Smith")
    @party.reload

    @tm = TeamMember.create!(agency: @agency, party: @party, status: "active")
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "employee",
      title: "Advisor",
      status: "draft"
    )

    dt = DocumentType.create!(
      agency: @agency,
      name: "ID #{SecureRandom.hex(2)}",
      code: "id#{SecureRandom.hex(2)}",
      category: "other",
      status: "active"
    )
    @doc = DocumentRecord.create!(
      agency: @agency,
      document_type: dt,
      team_member: @tm,
      party: @party,
      display_name: "Passport",
      filename: "p.pdf",
      content_type: "application/pdf",
      byte_size: 100,
      storage_key: "k/#{SecureRandom.hex(4)}",
      status: "submitted",
      submitted_on: Date.current
    )

    PartyContactMethod.create!(
      party: @party,
      contact_type: "email",
      value: "jane@example.com",
      is_primary: true,
      status: "active"
    )

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "party show loads hub panels when populated" do
    get admin_party_path(@party)
    assert_response :success
    assert_includes @response.body, "Identity details"
    assert_includes @response.body, "Contact methods"
    assert_includes @response.body, "Workforce participation"
    assert_includes @response.body, "Engagements"
    assert_includes @response.body, "Documents tagged to this party"
    assert_includes @response.body, "jane@example.com"
    assert_includes @response.body, "Team360"
  end

  test "nested new party contact method 404 for party in other agency" do
    other = Agency.create!(name: "Oth", code: "oth#{SecureRandom.hex(4)}")
    alien = Party.create!(agency: other, party_type: "person", display_name: "Alien")
    PersonProfile.create!(party: alien, first_name: "A", last_name: "B")
    alien.reload

    get new_admin_party_party_contact_method_path(alien)
    assert_response :not_found
  end

  test "nested edit party contact method 404 when record belongs to another party" do
    other_party = Party.create!(agency: @agency, party_type: "person", display_name: "Other")
    PersonProfile.create!(party: other_party, first_name: "O", last_name: "P")
    other_party.reload

    pcm = PartyContactMethod.create!(
      party: other_party,
      contact_type: "phone",
      value: "555",
      status: "active",
      is_primary: false
    )

    get edit_admin_party_party_contact_method_path(@party, pcm)
    assert_response :not_found
  end

  test "patch contact method with wrong nested party returns not found" do
    other_party = Party.create!(agency: @agency, party_type: "person", display_name: "Other2")
    PersonProfile.create!(party: other_party, first_name: "O", last_name: "Q")
    other_party.reload

    pcm = PartyContactMethod.create!(
      party: other_party,
      contact_type: "phone",
      value: "555",
      status: "active",
      is_primary: false
    )

    patch admin_party_party_contact_method_path(@party, pcm), params: {
      party_contact_method: { value: "nope", contact_type: "phone", status: "active", is_primary: "0" }
    }
    assert_response :not_found
  end

  test "create contact method demotes prior active primary for same type" do
    first = PartyContactMethod.find_by!(party: @party, contact_type: "email", is_primary: true)

    assert_difference -> { PartyContactMethod.count }, 1 do
      post admin_party_party_contact_methods_path(@party), params: {
        party_contact_method: {
          contact_type: "email",
          value: "second@example.com",
          status: "active",
          is_primary: "1"
        }
      }
    end
    assert_redirected_to admin_party_path(@party)

    refute first.reload.is_primary?
    second = PartyContactMethod.where(party: @party, value: "second@example.com").first
    assert second.is_primary?
  end

  test "engagement new preselects team_member_id from query" do
    get new_admin_engagement_path(team_member_id: @tm.id)
    assert_response :success
    assert_select "select[name='engagement[team_member_id]'] option[selected][value='#{@tm.id}']"
  end

  test "team member new preselects party_id when eligible" do
    solo = Party.create!(agency: @agency, party_type: "person", display_name: "Solo")
    PersonProfile.create!(party: solo, first_name: "S", last_name: "O")
    solo.reload

    get new_admin_team_member_path(party_id: solo.id)
    assert_response :success
    assert_select "select[name='team_member[party_id]'] option[selected][value='#{solo.id}']"
  end

  test "team member new does not preselect ineligible party_id" do
    get new_admin_team_member_path(party_id: @party.id)
    assert_response :success
    refute_select "select[name='team_member[party_id]'] option[selected]"
  end
end

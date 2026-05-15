# frozen_string_literal: true

require "test_helper"

class AdminPartyRelationshipsTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Adm", code: "adm#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "u#{SecureRandom.hex(6)}@ex.com",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    @org = Party.create!(agency: @agency, party_type: "organization", display_name: "CO")
    OrganizationProfile.create!(
      party: @org,
      legal_name: "Contractor Org LLC",
      organization_kind: "contractor_organization"
    )
    @org.reload

    @target = Party.create!(agency: @agency, party_type: "person", display_name: "Maria")
    PersonProfile.create!(party: @target, first_name: "Maria", last_name: "Sub")
    @target.reload

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "nested index loads" do
    get admin_party_party_relationships_path(@org)
    assert_response :success
  end

  test "create subcontractor relationship" do
    assert_difference -> { PartyRelationship.count }, 1 do
      post admin_party_party_relationships_path(@org), params: {
        party_relationship: { target_party_id: @target.id, status: "active" }
      }
    end
    assert_redirected_to admin_party_party_relationships_path(@org)
  end

  test "reject target party from another agency" do
    other = Agency.create!(name: "Oth", code: "oth#{SecureRandom.hex(4)}")
    alien = Party.create!(agency: other, party_type: "person", display_name: "Alien")
    PersonProfile.create!(party: alien, first_name: "Alien", last_name: "Party")
    alien.reload

    assert_no_difference -> { PartyRelationship.count } do
      post admin_party_party_relationships_path(@org), params: {
        party_relationship: { target_party_id: alien.id, status: "active" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "promote redirects to engagement" do
    PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: @target,
      relationship_type: "subcontractor",
      status: "active"
    )
    rel = PartyRelationship.last

    post promote_admin_party_party_relationship_path(@org, rel)
    assert_response :redirect
    assert_match(%r{/admin/engagements/\d+}, @response.redirect_url)
  end

  test "stale source warning appears on index for person source without IC" do
    person_src = Party.create!(agency: @agency, party_type: "person", display_name: "IC")
    PersonProfile.create!(party: person_src, first_name: "IC", last_name: "Src")
    person_src.reload
    tm = TeamMember.create!(agency: @agency, party: person_src)
    e = Engagement.create!(agency: @agency, team_member: tm, relationship_type: "individual_contractor")
    e.update!(status: "pending") if e.status == "draft"
    e.update!(status: "active", start_on: Date.current)

    PartyRelationship.create!(
      agency: @agency,
      source_party: person_src,
      target_party: @target,
      relationship_type: "subcontractor",
      status: "active"
    )
    e.update!(status: "suspended")

    get admin_party_party_relationships_path(person_src)
    assert_response :success
    assert_match(/no longer contractor-capable/i, @response.body)
  end
end

# frozen_string_literal: true

require "test_helper"

class PartyRelationshipTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "PR", code: "pr#{SecureRandom.hex(4)}")
    @org = Party.create!(agency: @agency, party_type: "organization", display_name: "Contractor Org")
    OrganizationProfile.create!(
      party: @org,
      legal_name: "Contractor Org LLC",
      organization_kind: "contractor_organization"
    )
    @org.reload

    @person = Party.create!(agency: @agency, party_type: "person", display_name: "Sam Contact")
    PersonProfile.create!(party: @person, first_name: "Sam", last_name: "Contact")
    @person.reload
  end

  test "blocks self reference" do
    rel = PartyRelationship.new(
      agency: @agency,
      source_party: @person,
      target_party: @person,
      relationship_type: "related_contact"
    )

    assert_not rel.valid?
  end

  test "primary_contact requires org source and person target" do
    rel = PartyRelationship.new(
      agency: @agency,
      source_party: @person,
      target_party: @org,
      relationship_type: "primary_contact"
    )

    assert_not rel.valid?
  end

  test "only one active primary contact per org" do
    PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: @person,
      relationship_type: "primary_contact",
      status: "active"
    )

    other_person = Party.create!(agency: @agency, party_type: "person", display_name: "Jane")
    PersonProfile.create!(party: other_person, first_name: "Jane", last_name: "Other")
    other_person.reload

    conflict = PartyRelationship.new(
      agency: @agency,
      source_party: @org,
      target_party: other_person,
      relationship_type: "primary_contact",
      status: "active"
    )

    assert_not conflict.valid?
  end
end

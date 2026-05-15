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

  def ic_person_source!
    person = Party.create!(agency: @agency, party_type: "person", display_name: "IC Source")
    PersonProfile.create!(party: person, first_name: "IC", last_name: "Source")
    person.reload
    tm = TeamMember.create!(agency: @agency, party: person)
    e = Engagement.create!(
      agency: @agency,
      team_member: tm,
      relationship_type: "individual_contractor"
    )
    e.update!(status: "pending") if e.status == "draft"
    e.update!(status: "active", start_on: Date.current)
    person
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

  #
  # TC-05 — subcontractor
  #

  test "subcontractor allows contractor organization source" do
    rel = PartyRelationship.new(
      agency: @agency,
      source_party: @org,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )

    assert rel.valid?
  end

  test "subcontractor rejects non-contractor organization source" do
    vendor = Party.create!(agency: @agency, party_type: "organization", display_name: "Vendor")
    OrganizationProfile.create!(party: vendor, legal_name: "V", organization_kind: "vendor")
    vendor.reload

    rel = PartyRelationship.new(
      agency: @agency,
      source_party: vendor,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )

    assert_not rel.valid?
    assert rel.errors[:source_party].present?
  end

  test "subcontractor allows person source with active individual contractor engagement" do
    src = ic_person_source!

    rel = PartyRelationship.new(
      agency: @agency,
      source_party: src,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )

    assert rel.valid?
  end

  test "subcontractor rejects person source without active IC engagement" do
    person = Party.create!(agency: @agency, party_type: "person", display_name: "Plain")
    PersonProfile.create!(party: person, first_name: "Plain", last_name: "Person")
    person.reload

    rel = PartyRelationship.new(
      agency: @agency,
      source_party: person,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )

    assert_not rel.valid?
  end

  test "subcontractor blocks overlapping active intervals for same pair" do
    sub = Party.create!(agency: @agency, party_type: "person", display_name: "Sub")
    PersonProfile.create!(party: sub, first_name: "Sub", last_name: "One")
    sub.reload

    PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: sub,
      relationship_type: "subcontractor",
      status: "active",
      effective_start_date: Date.new(2024, 1, 1),
      effective_end_date: Date.new(2024, 6, 30)
    )

    overlap = PartyRelationship.new(
      agency: @agency,
      source_party: @org,
      target_party: sub,
      relationship_type: "subcontractor",
      status: "active",
      effective_start_date: Date.new(2024, 6, 1),
      effective_end_date: nil
    )

    assert_not overlap.valid?
    assert overlap.errors[:base].join.match?(/overlap/i)
  end

  test "subcontractor allows non-overlapping active rows when window is disjoint" do
    sub = Party.create!(agency: @agency, party_type: "person", display_name: "Sub")
    PersonProfile.create!(party: sub, first_name: "Sub", last_name: "Two")
    sub.reload

    PartyRelationship.create!(
      agency: @agency,
      source_party: @org,
      target_party: sub,
      relationship_type: "subcontractor",
      status: "active",
      effective_start_date: Date.new(2023, 1, 1),
      effective_end_date: Date.new(2023, 12, 31)
    )

    second = PartyRelationship.new(
      agency: @agency,
      source_party: @org,
      target_party: sub,
      relationship_type: "subcontractor",
      status: "active",
      effective_start_date: Date.new(2024, 1, 1),
      effective_end_date: nil
    )

    assert second.valid?, second.errors.full_messages.inspect
  end

  test "subcontractor enforces effective end on or after start" do
    rel = PartyRelationship.new(
      agency: @agency,
      source_party: @org,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active",
      effective_start_date: Date.new(2024, 2, 1),
      effective_end_date: Date.new(2024, 1, 1)
    )

    assert_not rel.valid?
    assert rel.errors[:effective_end_date].present?
  end

  test "subcontractor_contact does not apply subcontractor source rules" do
    vendor = Party.create!(agency: @agency, party_type: "organization", display_name: "Vendor")
    OrganizationProfile.create!(party: vendor, legal_name: "V", organization_kind: "vendor")
    vendor.reload

    rel = PartyRelationship.new(
      agency: @agency,
      source_party: vendor,
      target_party: @person,
      relationship_type: "subcontractor_contact",
      status: "active"
    )

    assert rel.valid?
  end

  test "stale person source blocks updates that would save" do
    src = ic_person_source!
    rel = PartyRelationship.create!(
      agency: @agency,
      source_party: src,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )
    eng = Engagement.joins(:team_member).find_by!(
      agency_id: @agency.id,
      relationship_type: "individual_contractor",
      status: "active",
      team_members: { party_id: src.id }
    )
    eng.update!(status: "suspended")

    rel.notes = "touch"
    assert_not rel.save
    assert rel.errors[:source_party].present?
  end

  test "subcontractor_person_source_stale_for_display when IC suspended" do
    src = ic_person_source!
    rel = PartyRelationship.create!(
      agency: @agency,
      source_party: src,
      target_party: @person,
      relationship_type: "subcontractor",
      status: "active"
    )
    eng = Engagement.joins(:team_member).find_by!(
      agency_id: @agency.id,
      relationship_type: "individual_contractor",
      status: "active",
      team_members: { party_id: src.id }
    )
    eng.update!(status: "suspended")

    assert rel.reload.subcontractor_person_source_stale_for_display?
  end
end

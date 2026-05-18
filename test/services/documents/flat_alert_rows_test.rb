# frozen_string_literal: true

require "test_helper"

class DocumentsFlatAlertRowsTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Flat Rows Agency", code: "fra#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Lee")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.new(2026, 1, 10))

    @doc_type = DocumentType.create!(
      agency: @agency,
      code: "tc07_w9",
      name: "W-9",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )

    DocumentRequirement.create!(
      agency: @agency,
      document_type: @doc_type,
      name: "Federal W-9",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: true,
      status: "active"
    )
  end

  test "build surfaces evaluator missing alerts across engagements" do
    as_of = Date.new(2026, 3, 1)
    rows =
      Documents::FlatAlertRows.build(
        agency_id: @agency.id,
        as_of_date: as_of,
        include_terminal: false
      )

    assert(rows.any? { |r| r.engagement.id == @engagement.id && r.alert.alert_type == "missing" })
  end

  test "build filters by alert_type" do
    as_of = Date.new(2026, 3, 1)
    rows =
      Documents::FlatAlertRows.build(
        agency_id: @agency.id,
        as_of_date: as_of,
        include_terminal: false,
        alert_type: "missing"
      )

    assert rows.any?
    assert(rows.all? { |r| r.alert.alert_type == "missing" })
  end

  test "build is deterministic for identical inputs" do
    as_of = Date.new(2026, 3, 1)
    args = {
      agency_id: @agency.id,
      as_of_date: as_of,
      include_terminal: false
    }

    sig = lambda do |rows|
      rows.map { |r| [ r.engagement.id, r.alert.document_requirement_id, r.alert.alert_type ] }
    end

    first = Documents::FlatAlertRows.build(**args)
    second = Documents::FlatAlertRows.build(**args)
    assert_equal sig.call(first), sig.call(second)
  end

  test "excludes terminal engagements by default" do
    @engagement.update!(status: "ended", end_on: Date.new(2026, 2, 1))

    as_of = Date.new(2026, 3, 1)
    rows =
      Documents::FlatAlertRows.build(
        agency_id: @agency.id,
        as_of_date: as_of,
        include_terminal: false
      )

    assert_empty(rows.select { |r| r.engagement.id == @engagement.id })
  end

  test "sort_flat_rows orders consistently with engagement and team member tie-breakers" do
    party2 = Party.create!(agency: @agency, party_type: "person", display_name: "Quinn")
    PersonProfile.create!(party: party2, first_name: "Q", last_name: "U")
    party2.reload
    tm2 = TeamMember.create!(agency: @agency, party: party2)
    eng2 =
      Engagement.create!(
        agency: @agency,
        team_member: tm2,
        relationship_type: "employee",
        status: "active",
        start_on: Date.new(2026, 1, 12)
      )

    as_of = Date.new(2026, 3, 1)
    rows =
      Documents::FlatAlertRows.build(
        agency_id: @agency.id,
        as_of_date: as_of,
        include_terminal: false,
        alert_type: "missing"
      )

    ours = rows.select { |r| [ @engagement.id, eng2.id ].include?(r.engagement.id) }
    assert_equal 2, ours.size
    assert_operator ours.first.engagement.id, :<=, ours.second.engagement.id
  end
end

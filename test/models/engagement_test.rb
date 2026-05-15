# frozen_string_literal: true

require "test_helper"

class EngagementTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Eng Agency", code: "eng#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Person")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Person")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
  end

  test "defaults to draft status" do
    e = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")

    assert_equal "draft", e.status
  end

  test "rejects agency mismatch with team member" do
    other = Agency.create!(name: "Other", code: "oth#{SecureRandom.hex(4)}")
    e = Engagement.new(agency: other, team_member: @team_member, relationship_type: "employee")

    assert_not e.valid?
    assert_includes e.errors[:agency_id].join, "match"
  end

  test "employee relationship requires person party" do
    org = Party.create!(agency: @agency, party_type: "organization", display_name: "Org")
    OrganizationProfile.create!(
      party: org,
      legal_name: "Org LLC",
      trade_name: "Org",
      organization_kind: "vendor"
    )
    org.reload
    tm = TeamMember.create!(agency: @agency, party: org)
    e = Engagement.new(agency: @agency, team_member: tm, relationship_type: "employee")

    assert_not e.valid?
    assert e.errors[:relationship_type].present?
  end

  test "contractor_organization requires organization party" do
    e = Engagement.new(agency: @agency, team_member: @team_member, relationship_type: "contractor_organization")

    assert_not e.valid?
    assert e.errors[:relationship_type].present?
  end

  test "MVP status path draft to active" do
    e = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")
    assert e.update!(status: "pending")
    assert e.update!(status: "active", start_on: Date.current)

    assert_equal "active", e.reload.status
  end

  test "active requires start_on and forbids end_on" do
    e = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    e.status = "active"
    assert_not e.valid?
    assert e.errors[:start_on].present?

    e.start_on = Date.current
    e.end_on = Date.current
    assert_not e.valid?
    assert e.errors[:end_on].present?
  end

  test "ended requires start_on and end_on" do
    e = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    e.update!(status: "active", start_on: 1.year.ago.to_date)
    e.status = "ended"
    assert_not e.valid?
    assert e.errors[:end_on].present?

    e.end_on = Date.current
    assert e.valid?
  end

  test "cannot leave terminal status" do
    e = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    e.update!(status: "active", start_on: 1.month.ago.to_date)
    e.update!(status: "ended", end_on: Date.current)

    e.status = "active"
    assert_not e.valid?
    assert_includes e.errors[:status].join, "terminal"
  end

  test "at most one active engagement per agency, team member, and relationship type" do
    e1 = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")
    e1.update!(status: "pending")
    e1.update!(status: "active", start_on: Date.current)

    e2 = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")
    e2.update!(status: "pending")

    assert_not e2.update(status: "active", start_on: Date.current)
    assert_includes e2.errors[:base].join, "already has an active"
  end

  test "allows two active engagements when relationship types differ" do
    org = Party.create!(agency: @agency, party_type: "organization", display_name: "Vendor Co")
    OrganizationProfile.create!(
      party: org,
      legal_name: "Vendor Co",
      trade_name: "Vendor Co",
      organization_kind: "vendor"
    )
    org.reload

    ee = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")
    ee.update!(status: "pending")
    ee.update!(status: "active", start_on: Date.current)

    tm2 = TeamMember.create!(agency: @agency, party: org)
    sub = Engagement.create!(agency: @agency, team_member: tm2, relationship_type: "subcontractor")
    sub.update!(status: "pending")
    assert sub.update!(status: "active", start_on: Date.current)
  end
end

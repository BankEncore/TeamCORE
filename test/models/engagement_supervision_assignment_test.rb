# frozen_string_literal: true

require "test_helper"

class EngagementSupervisionAssignmentTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Sup Agency", code: "sup#{SecureRandom.hex(4)}")
    @jane_party = Party.create!(agency: @agency, party_type: "person", display_name: "Jane E")
    PersonProfile.create!(party: @jane_party, first_name: "Jane", last_name: "Employee")
    @jane_party.reload
    @jane_tm = TeamMember.create!(agency: @agency, party: @jane_party)

    @rob_party = Party.create!(agency: @agency, party_type: "person", display_name: "Robert C")
    PersonProfile.create!(party: @rob_party, first_name: "Robert", last_name: "Contractor")
    @rob_party.reload
    @rob_tm = TeamMember.create!(agency: @agency, party: @rob_party)

    @org_party = Party.create!(agency: @agency, party_type: "organization", display_name: "Contractor Org")
    OrganizationProfile.create!(
      party: @org_party,
      legal_name: "Contractor Org LLC",
      trade_name: "Contractor Org",
      organization_kind: "contractor_organization"
    )
    @org_party.reload
    @org_tm = TeamMember.create!(agency: @agency, party: @org_party)

    @supervisor = create_active_employee_engagement(@jane_tm)
    @supervised_ic = create_active_ic_engagement(@rob_tm)
    @contractor_org_eng = create_active_contractor_org_engagement(@org_tm)
  end

  test "creates primary_reports_to from employee supervisor to contractor engagement" do
    a = EngagementSupervisionAssignment.create!(
      engagement: @supervised_ic,
      supervisor_engagement: @supervisor,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.current
    )

    assert_equal @agency.id, a.agency_id
    assert_predicate a, :persisted?
  end

  test "forbids self-supervision" do
    a = EngagementSupervisionAssignment.new(
      engagement: @supervisor,
      supervisor_engagement: @supervisor,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.current
    )

    assert_not a.valid?
    assert a.errors[:supervisor_engagement_id].present?
  end

  test "MVP forbids contractor_organization engagement as supervisor" do
    a = EngagementSupervisionAssignment.new(
      engagement: @supervised_ic,
      supervisor_engagement: @contractor_org_eng,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.current
    )

    assert_not a.valid?
    assert_includes a.errors[:supervisor_engagement_id].join, "contractor organization"
  end

  test "MVP requires supervisor to be employee engagement" do
    ic_sup = create_active_ic_engagement(@jane_tm)
    a = EngagementSupervisionAssignment.new(
      engagement: @supervised_ic,
      supervisor_engagement: ic_sup,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.current
    )

    assert_not a.valid?
    assert_includes a.errors[:supervisor_engagement_id].join, "employee"
  end

  test "rejects overlapping supervision intervals for same supervised engagement" do
    EngagementSupervisionAssignment.create!(
      engagement: @supervised_ic,
      supervisor_engagement: @supervisor,
      effective_start_on: Date.new(2026, 1, 1),
      effective_end_on: Date.new(2026, 6, 30)
    )

    other_person = Party.create!(agency: @agency, party_type: "person", display_name: "Other Sup")
    PersonProfile.create!(party: other_person, first_name: "Other", last_name: "Supervisor")
    other_person.reload
    other_tm = TeamMember.create!(agency: @agency, party: other_person)
    other_sup = create_active_employee_engagement(other_tm)

    dup = EngagementSupervisionAssignment.new(
      engagement: @supervised_ic,
      supervisor_engagement: other_sup,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.new(2026, 6, 1)
    )

    assert_not dup.valid?
    assert_includes dup.errors[:base].join, "overlaps"
  end

  private

  def create_active_employee_engagement(team_member)
    e = Engagement.create!(agency: @agency, team_member:, relationship_type: "employee")
    e.update!(status: "pending")
    e.update!(status: "active", start_on: Date.current)
    e
  end

  def create_active_ic_engagement(team_member)
    e = Engagement.create!(agency: @agency, team_member:, relationship_type: "individual_contractor")
    e.update!(status: "pending")
    e.update!(status: "active", start_on: Date.current)
    e
  end

  def create_active_contractor_org_engagement(team_member)
    e = Engagement.create!(agency: @agency, team_member:, relationship_type: "contractor_organization")
    e.update!(status: "pending")
    e.update!(status: "active", start_on: Date.current)
    e
  end
end

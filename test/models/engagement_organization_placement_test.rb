# frozen_string_literal: true

require "test_helper"

class EngagementOrganizationPlacementTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Plc Agency", code: "plc#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Placed")
    PersonProfile.create!(party: @party, first_name: "Pl", last_name: "Aced")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(agency: @agency, team_member: @team_member, relationship_type: "employee")
    @engagement.update!(status: "pending")
    @engagement.update!(status: "active", start_on: Date.current)

    @dept = Department.create!(agency: @agency, code: "d1", name: "Dept One")
    @loc = Location.create!(
      agency: @agency,
      code: "l1",
      name: "Loc One",
      location_type: "office"
    )
    @team = Team.create!(agency: @agency, code: "t1", name: "Team One", department: @dept, location: @loc)
  end

  test "syncs agency from engagement" do
    p = EngagementOrganizationPlacement.create!(
      engagement: @engagement,
      effective_start_on: Date.current,
      department: @dept
    )

    assert_equal @agency.id, p.agency_id
  end

  test "rejects department from another agency" do
    other = Agency.create!(name: "X", code: "x#{SecureRandom.hex(4)}")
    foreign_dept = Department.create!(agency: other, code: "fd", name: "Foreign")

    p = EngagementOrganizationPlacement.new(
      engagement: @engagement,
      effective_start_on: Date.current,
      department: foreign_dept
    )

    assert_not p.valid?
    assert p.errors[:department_id].present?
  end

  test "rejects overlapping placement intervals on same engagement" do
    start_a = Date.new(2026, 1, 1)
    EngagementOrganizationPlacement.create!(
      engagement: @engagement,
      effective_start_on: start_a,
      effective_end_on: Date.new(2026, 6, 30)
    )

    overlap = EngagementOrganizationPlacement.new(
      engagement: @engagement,
      effective_start_on: Date.new(2026, 6, 1),
      effective_end_on: Date.new(2026, 12, 31)
    )

    assert_not overlap.valid?
    assert_includes overlap.errors[:base].join, "overlaps"
  end

  test "allows adjacent placements without overlap" do
    EngagementOrganizationPlacement.create!(
      engagement: @engagement,
      effective_start_on: Date.new(2026, 1, 1),
      effective_end_on: Date.new(2026, 6, 30)
    )

    adjacent = EngagementOrganizationPlacement.new(
      engagement: @engagement,
      effective_start_on: Date.new(2026, 7, 1)
    )

    assert adjacent.valid?, adjacent.errors.full_messages.join(", ")
  end

  test "date_intervals_overlap detects inclusive overlap" do
    assert EngagementOrganizationPlacement.date_intervals_overlap?(
      Date.new(2026, 1, 1),
      Date.new(2026, 1, 31),
      Date.new(2026, 1, 31),
      Date.new(2026, 2, 28)
    )
  end
end

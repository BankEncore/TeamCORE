# frozen_string_literal: true

require "test_helper"

class Team360::FocusedEngagementResolverTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "F", code: "f#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "P")
    PersonProfile.create!(party: @party, first_name: "A", last_name: "B")
    @party.reload
    @tm = TeamMember.create!(agency: @agency, party: @party)
  end

  test "prefers explicit engagement_id when valid" do
    e1 = Engagement.create!(agency: @agency, team_member: @tm, relationship_type: "employee", status: "active", start_on: Date.current)
    e2 = Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "individual_contractor",
      status: "draft"
    )

    focused = Team360::FocusedEngagementResolver.call(team_member: @tm.reload, preferred_engagement_id: e2.id)
    assert_equal e2.id, focused.id
  end

  test "picks sole active engagement" do
    Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "individual_contractor",
      status: "draft"
    )
    active =
      Engagement.create!(
        agency: @agency,
        team_member: @tm,
        relationship_type: "employee",
        status: "active",
        start_on: Date.current
      )

    focused = Team360::FocusedEngagementResolver.call(team_member: @tm.reload, preferred_engagement_id: nil)
    assert_equal active.id, focused.id
  end

  test "deterministic pick among multiple actives" do
    e_lo = Engagement.create!(agency: @agency, team_member: @tm, relationship_type: "employee", status: "active", start_on: Date.current)
    e_hi = Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "individual_contractor",
      status: "active",
      start_on: Date.current
    )
    assert e_lo.id < e_hi.id

    focused = Team360::FocusedEngagementResolver.call(team_member: @tm.reload, preferred_engagement_id: nil)
    assert_equal e_lo.id, focused.id
  end

  test "falls back to most recent non-cancelled when none active" do
    Engagement.create!(
      agency: @agency,
      team_member: @tm,
      relationship_type: "employee",
      status: "ended",
      start_on: 3.months.ago.to_date,
      end_on: 1.month.ago.to_date
    )
    more_recent =
      Engagement.create!(
        agency: @agency,
        team_member: @tm,
        relationship_type: "employee",
        status: "terminated",
        start_on: 2.months.ago.to_date,
        end_on: 1.week.ago.to_date
      )

    focused = Team360::FocusedEngagementResolver.call(team_member: @tm.reload, preferred_engagement_id: nil)
    assert_equal more_recent.id, focused.id
  end
end

# frozen_string_literal: true

require "test_helper"

class EngagementWorkflowEligibilityTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Elig Agency", code: "elg#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Person")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Person")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
  end

  test "employee operational rails only when active" do
    Engagement::STATUSES.each do |st|
      e = Engagement.new(
        agency: @agency,
        team_member: @team_member,
        relationship_type: "employee",
        status: st
      )
      assert_equal st == "active", e.eligible_for_employee_operational_rails?
    end
  end

  test "non-employee types never use employee operational rails" do
    types = Engagement::RELATIONSHIP_TYPES - %w[employee]
    types.each do |rt|
      e = Engagement.new(
        agency: @agency,
        team_member: @team_member,
        relationship_type: rt,
        status: "active"
      )
      assert_not e.eligible_for_employee_operational_rails?
    end
  end

  test "contractor-class operational rails only when active" do
    EngagementWorkflowEligibility::CONTRACTOR_CLASS_RELATIONSHIP_TYPES.each do |rt|
      Engagement::STATUSES.each do |st|
        e = Engagement.new(
          agency: @agency,
          team_member: @team_member,
          relationship_type: rt,
          status: st
        )
        assert_equal st == "active", e.eligible_for_contractor_class_operational_rails?,
          "expected contractor-class eligibility for #{rt}/#{st}"
      end
    end
  end

  test "employee never uses contractor-class operational rails" do
    Engagement::STATUSES.each do |st|
      e = Engagement.new(
        agency: @agency,
        team_member: @team_member,
        relationship_type: "employee",
        status: st
      )
      assert_not e.eligible_for_contractor_class_operational_rails?
    end
  end

  test "operational forward work blocked for every non-active status" do
    Engagement::STATUSES.each do |st|
      e = Engagement.new(
        agency: @agency,
        team_member: @team_member,
        relationship_type: "employee",
        status: st
      )
      assert_equal st != "active", e.operational_forward_work_blocked_by_status?
    end
  end

  test "relationship type helpers match engagement relationship_type" do
    e = Engagement.new(relationship_type: "employee", status: "draft")
    assert e.employee_relationship?
    assert_not e.contractor_class_relationship?

    e.relationship_type = "individual_contractor"
    assert_not e.employee_relationship?
    assert e.contractor_class_relationship?
  end
end

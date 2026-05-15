# frozen_string_literal: true

require "test_helper"

class EngagementWorkflowEligibilityTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Elig Agency", code: "elg#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Person")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Person")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)

    org = Party.create!(agency: @agency, party_type: "organization", display_name: "Sub Co")
    OrganizationProfile.create!(
      party: org,
      legal_name: "Sub Co LLC",
      trade_name: "Sub Co",
      organization_kind: "vendor"
    )
    org.reload
    @org_team_member = TeamMember.create!(agency: @agency, party: org)
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
      tm = (rt == "contractor_organization") ? @org_team_member : @team_member
      e = Engagement.new(
        agency: @agency,
        team_member: tm,
        relationship_type: rt,
        status: "active"
      )
      assert_not e.eligible_for_employee_operational_rails?
    end
  end

  test "contractor-class operational rails only when active" do
    EngagementWorkflowEligibility::CONTRACTOR_CLASS_RELATIONSHIP_TYPES.each do |rt|
      tm = (rt == "contractor_organization") ? @org_team_member : @team_member
      Engagement::STATUSES.each do |st|
        e = Engagement.new(
          agency: @agency,
          team_member: tm,
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

  test "suspended status blocks operational forward eligibility and predicates align" do
    e = Engagement.new(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "suspended"
    )
    assert_predicate e, :suspended?
    assert e.operational_forward_work_blocked_by_status?
    assert_not e.active_for_time_tracking?
    assert_not e.eligible_for_employee_operational_rails?

    ic = Engagement.new(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "individual_contractor",
      status: "suspended",
      start_on: Date.current
    )
    assert_predicate ic, :suspended?
    assert ic.operational_forward_work_blocked_by_status?
    assert_not ic.active_for_contractor_settlement?
  end

  test "terminal statuses are not eligible for forward operational rails" do
    Engagement::TERMINAL_STATUSES.each do |st|
      e = Engagement.new(
        agency: @agency,
        team_member: @team_member,
        relationship_type: "employee",
        status: st
      )
      assert_predicate e, :terminal?
      assert e.operational_forward_work_blocked_by_status?
      assert_not e.eligible_for_employee_operational_rails?
      assert_not e.active_for_payroll_input?
    end
  end

  test "subcontractor path is contractor-class not employee-path" do
    e = Engagement.new(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "subcontractor",
      status: "active",
      start_on: Date.current
    )
    assert_predicate e, :subcontractor_path?
    assert e.contractor_class?
    assert_not e.employee_path?
    assert e.active_for_contractor_settlement?
    assert_not e.active_for_time_tracking?
    assert_not e.active_for_leave?
    assert_not e.active_for_payroll_input?
  end

  test "relationship type helpers mirror relationship_type for employee and contractor rows" do
    em = Engagement.new(relationship_type: "employee", status: "draft")
    assert_predicate em, :employee_path?
    assert_not em.contractor_class?

    ic = Engagement.new(relationship_type: "individual_contractor", status: "draft")
    assert_predicate ic, :individual_contractor_path?
    assert_not_predicate ic, :employee_path?
    assert_predicate ic, :contractor_class?

    coe = Engagement.new(relationship_type: "contractor_organization", status: "draft")
    assert_predicate coe, :contractor_organization_path?
    assert_predicate coe, :contractor_class?
  end

  test "party and team_member tables do not store workforce engagement relationship state" do
    workforce_like = %w[relationship_type engagement_status workforce_status employment_status operational_status]

    workload = workforce_like & Party.column_names
    assert_empty workload, "Party should not carry engagement workforce classifier columns"

    workload_tm = workforce_like & TeamMember.column_names
    assert_empty workload_tm, "TeamMember should not carry engagement workforce classifier columns"
  end

  test "per-rail employee aliases match consolidated employee operational hinge when active" do
    active = Engagement.new(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "active",
      start_on: Date.current
    )
    assert active.active_for_time_tracking?
    assert active.active_for_leave?
    assert active.active_for_payroll_input?

    consolidated = active.eligible_for_employee_operational_rails?
    assert_equal consolidated, active.active_for_time_tracking?
    assert_equal consolidated, active.active_for_leave?
    assert_equal consolidated, active.active_for_payroll_input?
  end

  test "contractor settlement hint matches contractor-class operational hinge when active" do
    e = Engagement.new(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "individual_contractor",
      status: "active",
      start_on: Date.current
    )
    assert_equal e.eligible_for_contractor_class_operational_rails?, e.active_for_contractor_settlement?
  end
end

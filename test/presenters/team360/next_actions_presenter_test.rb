# frozen_string_literal: true

require "test_helper"

class Team360NextActionsPresenterTest < ActiveSupport::TestCase
  test "employee placement gap yields blocking CTA with team360 return param" do
    agency = Agency.create!(name: "NBA", code: "nba#{SecureRandom.hex(4)}")
    party = Party.create!(agency: agency, party_type: "person", display_name: "E", status: "active")
    PersonProfile.create!(party: party, first_name: "E", last_name: "E")
    party.reload
    tm = TeamMember.create!(agency: agency, party: party, status: "active")
    eng = Engagement.create!(
      agency: agency,
      team_member: tm,
      relationship_type: "employee",
      title: "T",
      status: "active",
      start_on: Date.current
    )
    readiness = stub_readiness("ready", engagement_id: eng.id)
    checklist = Admin::EngagementSetupChecklistPresenter.new(
      engagement: eng,
      document_readiness: readiness,
      placement_rows: eng.engagement_organization_placements,
      supervision_rows: eng.engagement_supervision_assignments,
      workforce_financial_assignment: nil
    )
    snapshot = stub_snapshot(engagement_id: eng.id)

    presenter = Team360::NextActionsPresenter.new(
      team_member: tm,
      engagement: eng,
      snapshot: snapshot,
      checklist_presenter: checklist
    )
    placement_action = presenter.actions.find { |a| a.sort_key == :current_placement }
    assert placement_action
    assert_equal :blocking, placement_action.urgency
    assert_match(%r{/admin/engagements/#{eng.id}/placements/new}, placement_action.href)
    assert_includes placement_action.href, "team360_return_to="
    assert_includes CGI.unescape(placement_action.href), "/admin/team_members/#{tm.id}/team360"
  end

  test "sorts basic engagement details before placement when both need attention" do
    agency = Agency.create!(name: "NB2", code: "nb2#{SecureRandom.hex(4)}")
    party = Party.create!(agency: agency, party_type: "person", display_name: "E2", status: "active")
    PersonProfile.create!(party: party, first_name: "E", last_name: "2")
    party.reload
    tm = TeamMember.create!(agency: agency, party: party, status: "active")
    eng = Engagement.create!(
      agency: agency,
      team_member: tm,
      relationship_type: "employee",
      title: "",
      status: "active",
      start_on: Date.current
    )
    readiness = stub_readiness("ready", engagement_id: eng.id)
    checklist = Admin::EngagementSetupChecklistPresenter.new(
      engagement: eng,
      document_readiness: readiness,
      placement_rows: eng.engagement_organization_placements,
      supervision_rows: eng.engagement_supervision_assignments,
      workforce_financial_assignment: nil
    )
    snapshot = stub_snapshot(engagement_id: eng.id)

    presenter = Team360::NextActionsPresenter.new(
      team_member: tm,
      engagement: eng,
      snapshot: snapshot,
      checklist_presenter: checklist
    )
    keys = presenter.actions.map(&:sort_key)
    assert_includes keys, :basic_engagement_details
    assert_includes keys, :current_placement
    assert_operator keys.index(:basic_engagement_details), :<, keys.index(:current_placement)
  end

  test "document readiness warning maps to warning urgency and workbench href" do
    agency = Agency.create!(name: "NB3", code: "nb3#{SecureRandom.hex(4)}")
    party = Party.create!(agency: agency, party_type: "person", display_name: "E3", status: "active")
    PersonProfile.create!(party: party, first_name: "E", last_name: "3")
    party.reload
    tm = TeamMember.create!(agency: agency, party: party, status: "active")
    eng = Engagement.create!(
      agency: agency,
      team_member: tm,
      relationship_type: "individual_contractor",
      title: "T",
      status: "active",
      start_on: Date.current
    )
    readiness = stub_readiness("warning", engagement_id: eng.id)
    checklist = Admin::EngagementSetupChecklistPresenter.new(engagement: eng, document_readiness: readiness)
    snapshot = stub_snapshot(engagement_id: eng.id)

    presenter = Team360::NextActionsPresenter.new(
      team_member: tm,
      engagement: eng,
      snapshot: snapshot,
      checklist_presenter: checklist
    )
    doc_action = presenter.actions.find { |a| a.sort_key == :document_readiness }
    assert doc_action
    assert_equal :warning, doc_action.urgency
    assert_match(%r{/admin/document_workbench}, doc_action.href)
  end

  private

  def stub_readiness(status, engagement_id: 1)
    Documents::ReadinessResult.new(
      readiness_status: status,
      as_of_date: Date.current,
      engagement_id: engagement_id,
      requirements: [],
      alerts: []
    )
  end

  def stub_snapshot(engagement_id:)
    Team360::ProfileSnapshot.new(
      as_of_date: Date.current,
      focused_engagement_id: engagement_id,
      identity: {},
      contacts: [],
      engagement_summaries: [],
      current_engagement_ids: [],
      organization_context: nil,
      readiness_result: nil,
      document_types_by_id: {},
      records_by_id: {},
      subcontractor_rows: [],
      workforce_financial: nil,
      payroll_prep_panel: nil,
      weekly_timesheets_panel: nil,
      leave_panel: nil
    )
  end
end

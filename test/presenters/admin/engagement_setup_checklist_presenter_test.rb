# frozen_string_literal: true

require "test_helper"

class AdminEngagementSetupChecklistPresenterTest < ActiveSupport::TestCase
  test "employee without placement flags current placement" do
    agency = Agency.create!(name: "Chk", code: "chk#{SecureRandom.hex(4)}")
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
    readiness = stub_readiness("ready")
    p = Admin::EngagementSetupChecklistPresenter.new(
      engagement: eng,
      document_readiness: readiness,
      placement_rows: eng.engagement_organization_placements,
      supervision_rows: eng.engagement_supervision_assignments,
      workforce_financial_assignment: nil
    )
    placement_row = p.rows.find { |r| r.key == :current_placement }
    assert_equal "needs_attention", placement_row.bucket
  end

  test "contractor relationship marks placement supervision N/A" do
    agency = Agency.create!(name: "Chk2", code: "c2#{SecureRandom.hex(4)}")
    party = Party.create!(agency: agency, party_type: "person", display_name: "C", status: "active")
    PersonProfile.create!(party: party, first_name: "C", last_name: "C")
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
    readiness = stub_readiness("not_ready")
    p = Admin::EngagementSetupChecklistPresenter.new(engagement: eng, document_readiness: readiness)
    keys = p.rows.map(&:key)
    assert_includes keys, :current_placement
    assert_equal "not_applicable", p.rows.find { |r| r.key == :current_placement }.bucket
    assert_equal "not_applicable", p.rows.find { |r| r.key == :supervision }.bucket
  end

  private

  def stub_readiness(status)
    Documents::ReadinessResult.new(
      readiness_status: status,
      as_of_date: Date.current,
      engagement_id: 1,
      requirements: [],
      alerts: []
    )
  end
end

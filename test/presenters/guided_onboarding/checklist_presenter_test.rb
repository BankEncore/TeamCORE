# frozen_string_literal: true

require "test_helper"

class GuidedOnboardingChecklistPresenterTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "GOCL", code: "go#{SecureRandom.hex(4)}")
    @return_path = "/admin/guided/employee?q=ab"
  end

  test "pending party identity lists create-party CTAs when person flow" do
    p = GuidedOnboarding::ChecklistPresenter.new(
      agency: @agency,
      selected_party: nil,
      relationship_type: "employee",
      org_flow: false,
      guided_return_path: @return_path,
      search_q: "a",
      team_member_id_param: nil
    )

    row = p.rows.first
    assert_equal :party_identity, row.key
    assert_equal "pending", row.status
    assert_equal "Create person party", row.primary_label
    assert_match(%r{/admin/parties/new/person}, row.primary_href)
    assert_includes row.primary_href, "return_to="
    assert_equal "Create organization party", row.secondary_label
  end

  test "organization guided flow hides create-person primary CTA" do
    p = GuidedOnboarding::ChecklistPresenter.new(
      agency: @agency,
      selected_party: nil,
      relationship_type: "contractor_organization",
      org_flow: true,
      guided_return_path: @return_path
    )
    row = p.rows.first
    assert_nil row.primary_label
    assert_nil row.primary_href
    assert_equal "Create organization party", row.secondary_label
  end

  test "resolved engagement appends checklist-derived rows and activation" do
    party = Party.create!(agency: @agency, party_type: "person", display_name: "Sam", status: "active")
    PersonProfile.create!(party: party, first_name: "Sam", last_name: "Go")
    party.reload
    tm = TeamMember.create!(agency: @agency, party: party, status: "active")
    eng = Engagement.create!(
      agency: @agency,
      team_member: tm,
      relationship_type: "employee",
      title: "Rep",
      status: "active",
      start_on: Date.current
    )

    p = GuidedOnboarding::ChecklistPresenter.new(
      agency: @agency,
      selected_party: party,
      relationship_type: "employee",
      org_flow: false,
      guided_return_path: "/admin/guided/employee?party_id=#{party.id}"
    )
    rows = p.rows
    keys = rows.map(&:key)

    assert_includes keys, :party_identity
    assert_includes keys, :team_member_record
    assert_includes keys, :engagement_record
    assert_includes keys, :basic_engagement_details
    assert_includes keys, :current_placement
    assert_includes keys, :activation_readiness

    placement = rows.find { |r| r.key == :current_placement }
    assert_equal "needs_attention", placement.status
    assert_equal "Add placement", placement.primary_label
    assert_match(%r{/admin/engagements/#{eng.id}/placements/new}, placement.primary_href)
    assert_includes placement.primary_href, "return_to="

    activation = rows.find { |r| r.key == :activation_readiness }
    assert_equal "Open Team360", activation.primary_label
    assert_match(%r{/admin/team_members/#{tm.id}/team360}, activation.primary_href)
    assert_includes activation.primary_href, "engagement_id=#{eng.id}"
  end
end

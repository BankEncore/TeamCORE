# frozen_string_literal: true

require "test_helper"

class AdminDocumentAlertsTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Alerts Agency", code: "al#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "alerts#{SecureRandom.hex(6)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    party = Party.create!(agency: @agency, party_type: "person", display_name: "Taylor")
    PersonProfile.create!(party: party, first_name: "Taylor", last_name: "Worker")
    party.reload

    @team_member = TeamMember.create!(agency: @agency, party: party)

    @doc_type = DocumentType.create!(
      agency: @agency,
      code: "tc07_w9",
      name: "W-9 (TC07)",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )

    @requirement = DocumentRequirement.create!(
      agency: @agency,
      document_type: @doc_type,
      name: "Federal W-9",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: true,
      status: "active"
    )

    @active_engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @active_engagement.update!(status: "active", start_on: Date.new(2026, 1, 10))

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "engagement show surfaces alert message block" do
    get admin_engagement_path(@active_engagement)
    assert_response :success

    assert_includes response.body, @requirement.name
    assert_includes response.body, "missing: no usable document record"
  end

  test "document alerts index lists missing alert for agency" do
    get admin_document_alerts_path
    assert_response :success

    assert_includes response.body, "##{@active_engagement.id}"
    assert_includes response.body, "missing"
  end

  test "index excludes terminal engagements by default" do
    tm2 = duplicate_team_member("Ended Person")
    term = Engagement.create!(
      agency: @agency,
      team_member: tm2,
      relationship_type: "employee",
      status: "pending"
    )
    term.update!(status: "active", start_on: Date.new(2026, 1, 15))
    assert term.update(status: "ended", end_on: Date.new(2026, 2, 1))

    # ended engagement should still evaluate on its own detail page...
    result = Documents::ReadinessEvaluator.new(engagement: term, as_of_date: Date.new(2026, 3, 1)).call
    refute_empty result.alerts

    # ...but omitted from aggregate index unless include_terminal set
    get admin_document_alerts_path
    refute_match(/##{Regexp.escape(term.id.to_s)}\b/, response.body)

    get admin_document_alerts_path, params: { include_terminal: "1" }
    assert_match(/##{Regexp.escape(term.id.to_s)}\b/, response.body)
  end

  test "filters narrow results and agency isolation applies" do
    other_agency = Agency.create!(name: "Other Alerts", code: "oa#{SecureRandom.hex(4)}")
    stranger = Party.create!(agency: other_agency, party_type: "person", display_name: "Lee")
    PersonProfile.create!(party: stranger, first_name: "Lee", last_name: "Other")
    stranger.reload

    other_tm = TeamMember.create!(agency: other_agency, party: stranger)
    other_eng = Engagement.create!(
      agency: other_agency,
      team_member: other_tm,
      relationship_type: "employee",
      status: "pending"
    )
    other_eng.update!(status: "active", start_on: Date.new(2026, 1, 11))

    other_type = DocumentType.create!(
      agency: other_agency,
      code: "other_tc07_doc",
      name: "Outside doc type",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )
    DocumentRequirement.create!(
      agency: other_agency,
      document_type: other_type,
      name: "Outside requirement",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: true,
      status: "active"
    )

    # Default index only lists current agency engagements
    get admin_document_alerts_path
    assert_response :success
    assert_includes response.body, "##{@active_engagement.id}"
    assert_includes response.body, "Federal W-9"

    refute_includes response.body, "Outside requirement"
    refute_match(/#\b#{other_eng.id}\b/, response.body)

    get admin_document_alerts_path,
      params: { alert_type: "pending_verification" }
    assert_response :success
    refute_includes response.body, "##{@active_engagement.id}"

    get admin_document_alerts_path,
      params: {
        alert_type: "missing",
        relationship_type: "employee",
        document_type_id: @doc_type.id,
        team_member_id: @team_member.id
      }
    assert_response :success
    assert_match(/Federal W-9/, response.body)
    assert_includes response.body, "##{@active_engagement.id}"
  end

  private

  def duplicate_team_member(display_fragment)
    p = Party.create!(agency: @agency, party_type: "person", display_name: display_fragment)
    PersonProfile.create!(party: p, first_name: display_fragment.first(20), last_name: "X")
    p.reload
    TeamMember.create!(agency: @agency, party: p)
  end
end

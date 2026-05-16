# frozen_string_literal: true

require "test_helper"

class DocumentsReadinessEvaluatorTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Readiness Agency", code: "rea#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Eve")
    PersonProfile.create!(party: @party, first_name: "Eve", last_name: "Employee")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.new(2025, 1, 1))

    @w9 = DocumentType.create!(
      agency: @agency,
      code: "w9",
      name: "W-9",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )
    @req_any = DocumentRequirement.create!(
      agency: @agency,
      document_type: @w9,
      name: "W-9",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: true,
      status: "active"
    )
    @req_employee_only = DocumentRequirement.create!(
      agency: @agency,
      document_type: DocumentType.create!(
        agency: @agency,
        code: "handbook",
        name: "Handbook",
        category: "employee_agreement",
        verification_required: false,
        status: "active"
      ),
      name: "Handbook",
      requirement_scope: "engagement",
      relationship_type: "employee",
      required: true,
      verification_required: false,
      status: "active"
    )

    @user = User.create!(
      email: "verifier#{SecureRandom.hex(4)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
  end

  test "employee engagement evaluates employee-only requirement" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 5),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 6),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 5),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    assert_equal "ready", result.readiness_status
    by_req = result.requirements.index_by(&:document_requirement_id)
    assert_equal "satisfied", by_req[@req_any.id].requirement_outcome
    assert_equal "satisfied", by_req[@req_employee_only.id].requirement_outcome
  end

  test "prefers verified record over rejected when both exist" do
    d1 = Date.new(2025, 1, 1)
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "rejected",
      submitted_on: d1,
      verified_by: @user,
      verified_on: d1,
      rejection_reason: "Blurry scan",
      filename: "bad.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: d1,
      verified_by: @user,
      verified_on: d1,
      filename: "good.pdf",
      content_type: "application/pdf"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call
    row = result.requirements.find { |r| r.document_requirement_id == @req_any.id }

    assert_equal "satisfied", row.requirement_outcome
    assert_equal "verified", row.record_review_status
  end

  test "pending verification when verification required and submitted only" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )

    # Satisfy handbook only so readiness is not_ready for W-9
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    assert_equal "not_ready", result.readiness_status
    w9_row = result.requirements.find { |r| r.document_requirement_id == @req_any.id }

    assert_equal "pending_verification", w9_row.requirement_outcome
  end

  test "no alerts when all required requirements satisfied without alert outcomes" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 5),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 6),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 5),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    assert_equal "ready", result.readiness_status
    assert_empty result.alerts
  end

  test "blocking pending_verification alert derived from requirement evaluation" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    w9_alert = result.alerts.find { |a| a.document_requirement_id == @req_any.id }

    assert_equal "pending_verification", w9_alert.alert_type
    assert_equal "blocking", w9_alert.severity
    assert_predicate w9_alert.message, :present?
  end

  test "missing alert has nil record id and record_review_status" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    missing_alert = result.alerts.find { |a| a.alert_type == "missing" }

    assert_equal "missing", missing_alert.alert_type
    assert_nil missing_alert.document_record_id
    assert_nil missing_alert.record_review_status
    assert_equal @engagement.id, missing_alert.engagement_id
    assert_equal @team_member.id, missing_alert.team_member_id
  end

  test "expired alert exposes negative days_until_expiration" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 1),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 2),
      expires_on: Date.new(2025, 5, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    expired_alert = result.alerts.find { |a| a.alert_type == "expired" }

    assert_equal Date.new(2025, 5, 1), expired_alert.expires_on
    assert expired_alert.days_until_expiration.negative?

    assert_equal "blocking", expired_alert.severity
  end

  test "optional requirement missing does not emit alert" do
    optional_req = DocumentRequirement.create!(
      agency: @agency,
      document_type: DocumentType.create!(
        agency: @agency,
        code: "optional_cert",
        name: "Optional cert",
        category: "certification",
        status: "active",
        verification_required: false
      ),
      name: "Optional certification",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: false,
      verification_required: false,
      status: "active"
    )

    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 5),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 6),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 5),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    refute result.alerts.any? { |a| a.document_requirement_id == optional_req.id },
      "optional requirement should not produce alerts"
  end

  test "alerts sort blocking before warning and by document type code among missing" do
    dt_early = DocumentType.create!(agency: @agency, code: "aaa_misc", name: "AAA", category: "other", status: "active")
    dt_late = DocumentType.create!(agency: @agency, code: "zzz_misc", name: "ZZZ", category: "other", status: "active")
    DocumentRequirement.create!(
      agency: @agency,
      document_type: dt_late,
      name: "ZZZ req",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: false,
      status: "active"
    )
    DocumentRequirement.create!(
      agency: @agency,
      document_type: dt_early,
      name: "AAA req",
      requirement_scope: "engagement",
      relationship_type: "any",
      required: true,
      verification_required: false,
      status: "active"
    )

    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 1),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 2),
      expires_on: Date.new(2025, 7, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call

    missing_alerts = result.alerts.select { |a| a.alert_type == "missing" }
    expiring = result.alerts.select { |a| a.alert_type == "expiring_soon" }

    assert expiring.any?
    assert missing_alerts.size >= 2

    first_blocking_index = result.alerts.index { |a| a.alert_type == "missing" && a.document_type_id == dt_early.id }
    first_warning_index = result.alerts.index { |a| a.alert_type == "expiring_soon" }

    assert first_blocking_index < first_warning_index

    zzz_index = result.alerts.index { |a| a.document_type_id == dt_late.id }
    aaa_index = result.alerts.index { |a| a.document_type_id == dt_early.id }

    assert aaa_index < zzz_index
  end

  test "subcontractor engagement still evaluated when requirements exist" do
    sub_party = Party.create!(agency: @agency, party_type: "person", display_name: "Sub Person")
    PersonProfile.create!(party: sub_party, first_name: "Sub", last_name: "Person")
    sub_party.reload
    sub_tm = TeamMember.create!(agency: @agency, party: sub_party)
    sub_eng = Engagement.create!(
      agency: @agency,
      team_member: sub_tm,
      relationship_type: "subcontractor",
      status: "pending"
    )
    sub_eng.update!(status: "active", start_on: Date.new(2025, 1, 1))

    sub_type = DocumentType.create!(
      agency: @agency,
      code: "sub_agreement",
      name: "Sub agreement",
      category: "contractor_agreement",
      status: "active",
      verification_required: false
    )
    DocumentRequirement.create!(
      agency: @agency,
      document_type: sub_type,
      name: "Subcontractor agreement",
      requirement_scope: "engagement",
      relationship_type: "subcontractor",
      required: true,
      verification_required: false,
      status: "active"
    )

    result = Documents::ReadinessEvaluator.new(engagement: sub_eng, as_of_date: Date.new(2025, 6, 1)).call

    assert_equal "not_ready", result.readiness_status
    assert result.alerts.any? { |a| a.alert_type == "missing" }
  end

  test "voided best candidate skips to next verified record for same requirement" do
    d1 = Date.new(2025, 1, 1)
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "voided",
      submitted_on: d1,
      verified_by: @user,
      verified_on: d1,
      verification_notes: "Duplicate upload",
      filename: "old.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: d1,
      verified_by: @user,
      verified_on: d1,
      filename: "good.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: d1,
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call
    w9_row = result.requirements.find { |r| r.document_requirement_id == @req_any.id }

    assert_equal "satisfied", w9_row.requirement_outcome
    assert_equal "verified", w9_row.record_review_status
  end

  test "verified record past expires_on evaluates expired" do
    DocumentRecord.create!(
      agency: @agency,
      document_type: @w9,
      engagement: @engagement,
      team_member: @team_member,
      status: "verified",
      submitted_on: Date.new(2025, 1, 1),
      verified_by: @user,
      verified_on: Date.new(2025, 1, 2),
      expires_on: Date.new(2025, 4, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )
    DocumentRecord.create!(
      agency: @agency,
      document_type: @req_employee_only.document_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2025, 1, 2),
      filename: "ack.html",
      content_type: "text/html"
    )

    result = Documents::ReadinessEvaluator.new(engagement: @engagement, as_of_date: Date.new(2025, 6, 1)).call
    w9_row = result.requirements.find { |r| r.document_requirement_id == @req_any.id }

    assert_equal "expired", w9_row.requirement_outcome
    assert_equal "not_ready", result.readiness_status
  end
end

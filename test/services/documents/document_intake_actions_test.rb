# frozen_string_literal: true

require "test_helper"

class DocumentsDocumentIntakeActionsTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "IntakeCo", code: "in#{SecureRandom.hex(4)}")
    @dtype =
      DocumentType.create!(
        agency: @agency,
        code: "w9",
        name: "W-9",
        category: "tax_form",
        verification_required: true,
        status: "active"
      )
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Intake", status: "active")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Intake")
    @party.reload
    @tm = TeamMember.create!(agency: @agency, party: @party, status: "active")
    @req =
      DocumentRequirement.create!(
        agency: @agency,
        document_type: @dtype,
        requirement_scope: "engagement",
        relationship_type: "employee",
        status: "active",
        required: true,
        verification_required: true
      )
    @eng =
      Engagement.create!(
        agency: @agency,
        team_member: @tm,
        relationship_type: "employee",
        title: "Rep",
        status: "active",
        start_on: Date.current
      )
    @rt = "/admin/team_members/#{@tm.id}/team360"
    @tm360 = "/admin/team_members/#{@tm.id}/team360?engagement_id=#{@eng.id}"
  end

  test "missing requirement yields Add label linking to new intake path" do
    row =
      Documents::ReadinessEvaluator::RequirementEvaluation.new(
        document_requirement_id: @req.id,
        document_type_id: @dtype.id,
        requirement_scope: "engagement",
        relationship_type: "employee",
        required: true,
        verification_required: true,
        requirement_outcome: "missing",
        record_review_status: nil,
        document_record_id: nil,
        expires_on: nil
      )

    act =
      Documents::DocumentIntakeActions.from_requirement_evaluation(
        row,
        team_member: @tm,
        engagement: @eng,
        document_type: @dtype,
        return_to: @rt,
        team360_return_to: @tm360,
        as_of_date: Date.current
      )

    assert_equal :add_document, act.kind
    assert_match(%r{/admin/document_records/new}, act.primary_href)
    assert_includes act.primary_href, "intake=missing_requirement"
    assert_includes act.primary_href, "document_requirement_id=#{@req.id}"
    assert_includes act.primary_label, "W-9"
  end

  test "pending_verification with record links to record show" do
    rec =
      DocumentRecord.create!(
        agency: @agency,
        document_type: @dtype,
        team_member: @tm,
        engagement: @eng,
        status: "submitted",
        submitted_on: Date.current,
        filename: "x.pdf",
        storage_key: "x",
        content_type: "application/pdf",
        byte_size: 100
      )

    row =
      Documents::ReadinessEvaluator::RequirementEvaluation.new(
        document_requirement_id: @req.id,
        document_type_id: @dtype.id,
        requirement_scope: "engagement",
        relationship_type: "employee",
        required: true,
        verification_required: true,
        requirement_outcome: "pending_verification",
        record_review_status: "pending_review",
        document_record_id: rec.id,
        expires_on: nil
      )

    act =
      Documents::DocumentIntakeActions.from_requirement_evaluation(
        row,
        team_member: @tm,
        engagement: @eng,
        document_type: @dtype,
        return_to: @rt,
        team360_return_to: @tm360,
        as_of_date: Date.current
      )

    assert_equal :review, act.kind
    assert_match(%r{/admin/document_records/#{rec.id}}, act.primary_href)
    refute_match(%r{/new}, act.primary_href)
  end

  test "from_alert_result maps expired to renewal intake" do
    alert =
      Documents::AlertResult.new(
        alert_type: "expired",
        severity: "blocking",
        requirement_outcome: "expired",
        record_review_status: "verified",
        document_requirement_id: @req.id,
        document_type_id: @dtype.id,
        document_record_id: nil,
        engagement_id: @eng.id,
        team_member_id: @tm.id,
        expires_on: Date.current - 30,
        days_until_expiration: nil,
        rejection_reason: nil,
        message: "expired"
      )

    act =
      Documents::DocumentIntakeActions.from_alert_result(
        alert,
        engagement: @eng,
        team_member: @tm,
        document_type: @dtype,
        return_to: @rt,
        team360_return_to: @tm360,
        as_of_date: Date.current
      )

    assert_equal :add_renewal, act.kind
    assert_includes act.primary_href, "intake=renew_expired"
  end
end

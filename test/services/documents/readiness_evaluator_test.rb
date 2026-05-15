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
end

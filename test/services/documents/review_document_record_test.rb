# frozen_string_literal: true

require "test_helper"

class DocumentsReviewDocumentRecordTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "RV Agency", code: "rv#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Rick")
    PersonProfile.create!(party: @party, first_name: "Rick", last_name: "Verifier")
    @party.reload
    @team_member = TeamMember.create!(agency: @agency, party: @party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.new(2026, 1, 10))

    @doc_type = DocumentType.create!(
      agency: @agency,
      code: "rw9",
      name: "RW-9",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )

    @user = User.create!(
      email: "verifier_rw#{SecureRandom.hex(4)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
  end

  test "verify from submitted clears rejection_reason and records verifier" do
    record = submitted_record(extra: { rejection_reason: "Stale", verified_by_id: nil, verified_on: nil })

    result = Documents::ReviewDocumentRecord.call(
      document_record: record,
      action: :verify,
      reviewer: @user,
      notes: "Looks good"
    )

    assert_predicate result, :success?
    assert_equal "verified", record.reload.status
    assert_equal @user.id, record.verified_by_id
    assert_equal Date.current, record.verified_on
    assert_nil record.rejection_reason
    assert_equal "Looks good", record.verification_notes
  end

  test "reject requires reason" do
    record = submitted_record

    bad = Documents::ReviewDocumentRecord.call(
      document_record: record,
      action: :reject,
      reviewer: @user,
      rejection_reason: "   "
    )
    refute_predicate bad, :success?
    assert_equal "submitted", record.reload.status

    good = Documents::ReviewDocumentRecord.call(
      document_record: record,
      action: :reject,
      reviewer: @user,
      rejection_reason: "Blurry PDF",
      notes: "Needs resubmit"
    )
    assert_predicate good, :success?
    assert_equal "rejected", record.reload.status
    assert_equal "Blurry PDF", record.rejection_reason
    assert_equal "Needs resubmit", record.verification_notes
  end

  test "void from rejected preserves verifier and rejection_reason" do
    record = submitted_record

    Documents::ReviewDocumentRecord.call(
      document_record: record,
      action: :reject,
      reviewer: @user,
      rejection_reason: "Bad file"
    )
    record.reload
    rej_id = record.verified_by_id
    rej_on = record.verified_on

    result = Documents::ReviewDocumentRecord.call(
      document_record: record.reload,
      action: :void,
      reviewer: @user,
      notes: "Administrative wipe"
    )

    assert_predicate result, :success?
    record.reload
    assert_equal "voided", record.status
    assert_equal rej_id, record.verified_by_id
    assert_equal rej_on, record.verified_on
    assert_equal "Bad file", record.rejection_reason
    assert_equal "Administrative wipe", record.verification_notes
  end

  test "void without notes preserves prior verification_notes" do
    record = submitted_record
    Documents::ReviewDocumentRecord.call(
      document_record: record,
      action: :verify,
      reviewer: @user,
      notes: "First note"
    )
    Documents::ReviewDocumentRecord.call(document_record: record.reload, action: :void, reviewer: @user, notes: nil)
    assert_equal "First note", record.reload.verification_notes
  end

  test "cannot verify non-submitted records" do
    record = submitted_record
    Documents::ReviewDocumentRecord.call(document_record: record, action: :verify, reviewer: @user)

    stale = Documents::ReviewDocumentRecord.call(
      document_record: record.reload,
      action: :verify,
      reviewer: @user
    )
    refute_predicate stale, :success?
  end

  test "cannot act on voided record" do
    record = submitted_record
    Documents::ReviewDocumentRecord.call(document_record: record, action: :void, reviewer: @user)
    verify = Documents::ReviewDocumentRecord.call(document_record: record.reload, action: :verify, reviewer: @user)
    refute_predicate verify, :success?

    reject = Documents::ReviewDocumentRecord.call(
      document_record: record.reload,
      action: :reject,
      reviewer: @user,
      rejection_reason: "try"
    )
    refute_predicate reject, :success?
  end

  private

  def submitted_record(extra: {})
    DocumentRecord.create!(
      {
        agency: @agency,
        document_type: @doc_type,
        engagement: @engagement,
        team_member: @team_member,
        status: "submitted",
        submitted_on: Date.new(2026, 3, 1),
        filename: "w9.pdf",
        content_type: "application/pdf"
      }.merge(extra)
    )
  end
end

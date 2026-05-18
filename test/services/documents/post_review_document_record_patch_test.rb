# frozen_string_literal: true

require "test_helper"

class DocumentsPostReviewDocumentRecordPatchTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Patch Agency", code: "pch#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "patch#{SecureRandom.hex(4)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
    party = Party.create!(agency: @agency, party_type: "person", display_name: "Sam")
    PersonProfile.create!(party: party, first_name: "Sam", last_name: "Lee")
    party.reload
    @team_member = TeamMember.create!(agency: @agency, party: party)
    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "active",
      start_on: Date.new(2026, 1, 1)
    )
    @doc_type = DocumentType.create!(
      agency: @agency,
      code: "p_w9",
      name: "W-9",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )
    @record =
      DocumentRecord.create!(
        agency: @agency,
        document_type: @doc_type,
        engagement: @engagement,
        team_member: @team_member,
        status: "verified",
        submitted_on: Date.new(2026, 2, 1),
        verified_by: @user,
        verified_on: Date.new(2026, 2, 2),
        filename: "w9.pdf",
        content_type: "application/pdf"
      )
  end

  test "applies allowed metadata changes" do
    exp = Date.new(2028, 6, 30)
    result =
      Documents::PostReviewDocumentRecordPatch.call(
        document_record: @record,
        attributes: { "expires_on" => exp, "display_name" => "Alias" }
      )

    assert_predicate result, :success?
    @record.reload
    assert_equal exp, @record.expires_on
    assert_equal "Alias", @record.display_name
  end

  test "rejects unknown attribute keys" do
    result =
      Documents::PostReviewDocumentRecordPatch.call(
        document_record: @record,
        attributes: { "display_name" => "ok", "status" => "submitted" }
      )

    assert_not result.success?
    assert_match(/disallowed attributes/i, result.error_messages.join)
    @record.reload
    refute_equal "ok", @record.display_name
    assert_equal "verified", @record.status
  end
end

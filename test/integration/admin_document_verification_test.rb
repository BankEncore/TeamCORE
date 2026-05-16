# frozen_string_literal: true

require "test_helper"

class AdminDocumentVerificationTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Ver Agency", code: "ver#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "veradmin#{SecureRandom.hex(6)}@ex.test",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)

    party = Party.create!(agency: @agency, party_type: "person", display_name: "Taylor")
    PersonProfile.create!(party: party, first_name: "Taylor", last_name: "Worker")
    party.reload

    @team_member = TeamMember.create!(agency: @agency, party: party)

    @engagement = Engagement.create!(
      agency: @agency,
      team_member: @team_member,
      relationship_type: "employee",
      status: "pending"
    )
    @engagement.update!(status: "active", start_on: Date.new(2026, 1, 12))

    @doc_type = DocumentType.create!(
      agency: @agency,
      code: "intf_w9",
      name: "INTF W9",
      category: "tax_form",
      verification_required: true,
      status: "active"
    )

    @record = DocumentRecord.create!(
      agency: @agency,
      document_type: @doc_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2026, 2, 1),
      filename: "w9.pdf",
      content_type: "application/pdf"
    )

    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "verify submitted record via POST" do
    post verify_admin_document_record_path(@record), params: { verification_notes: "OK" }
    assert_redirected_to admin_document_record_path(@record)
    assert_equal "verified", @record.reload.status
    assert_nil @record.rejection_reason
    assert_equal "OK", @record.verification_notes
  end

  test "reject requires reason returns 422" do
    post reject_admin_document_record_path(@record), params: {
      rejection_reason: "",
      verification_notes: "x"
    }
    assert_response :unprocessable_entity
    assert_equal "submitted", @record.reload.status
  end

  test "reject with reason succeeds" do
    post reject_admin_document_record_path(@record),
      params: { rejection_reason: "Too dark", verification_notes: "See email" }

    assert_redirected_to admin_document_record_path(@record)
    @record.reload
    assert_equal "rejected", @record.status
    assert_equal "Too dark", @record.rejection_reason
  end

  test "void from rejected preserves rejection_reason" do
    post reject_admin_document_record_path(@record), params: { rejection_reason: "Bad" }
    @record.reload

    post void_admin_document_record_path(@record), params: { verification_notes: "Administrative duplicate" }

    assert_redirected_to admin_document_record_path(@record)
    @record.reload
    assert_equal "voided", @record.status
    assert_equal "Bad", @record.rejection_reason
    assert_equal "Administrative duplicate", @record.verification_notes
  end

  test "cannot verify verified record twice" do
    post verify_admin_document_record_path(@record)

    post verify_admin_document_record_path(@record.reload)
    assert_response :unprocessable_entity
    assert_equal "verified", @record.reload.status
  end

  test "cannot update review status via edit form" do
    post verify_admin_document_record_path(@record)
    @record.reload

    patch admin_document_record_path(@record), params: {
      document_record: {
        rejection_reason: "Should not persist",
        status: "submitted",
        verified_by_id: nil,
        display_name: "Alias"
      }
    }
    assert_response :redirect
    @record.reload
    assert_equal "verified", @record.status
    assert_nil @record.rejection_reason
    assert_equal "Alias", @record.display_name
  end

  test "agency isolation on review endpoints" do
    other_agency = Agency.create!(name: "Other VA", code: "ova#{SecureRandom.hex(4)}")
    outsider = Party.create!(agency: other_agency, party_type: "person", display_name: "Out")
    PersonProfile.create!(party: outsider, first_name: "O", last_name: "Out")
    outsider.reload

    ot = TeamMember.create!(agency: other_agency, party: outsider)
    oe = Engagement.create!(
      agency: other_agency,
      team_member: ot,
      relationship_type: "employee",
      status: "pending"
    )
    oe.update!(status: "active", start_on: Date.new(2026, 1, 1))

    dt = DocumentType.create!(
      agency: other_agency,
      code: "ix",
      name: "IXDoc",
      category: "tax_form",
      verification_required: false,
      status: "active"
    )

    foreign = DocumentRecord.create!(
      agency: other_agency,
      document_type: dt,
      engagement: oe,
      team_member: ot,
      status: "submitted",
      submitted_on: Date.new(2026, 2, 2),
      filename: "x.pdf",
      content_type: "application/pdf"
    )

    post verify_admin_document_record_path(foreign), params: { verification_notes: "hack" }

    assert_response :not_found
  end

  test "pending review index lists only submitted rows" do
    post verify_admin_document_record_path(@record)

    nr = DocumentRecord.create!(
      agency: @agency,
      document_type: @doc_type,
      engagement: @engagement,
      team_member: @team_member,
      status: "submitted",
      submitted_on: Date.new(2026, 3, 1),
      filename: "w92.pdf",
      content_type: "application/pdf"
    )

    get admin_document_reviews_path
    assert_response :success

    assert_includes response.body, "##{nr.id}"
    refute_includes response.body, "##{@record.reload.id}"
  end
end

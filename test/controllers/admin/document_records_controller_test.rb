# frozen_string_literal: true

require "test_helper"

class Admin::DocumentRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "DocRecCtl", code: "dr#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "dr#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: @user, agency: @agency)

    @dtype =
      DocumentType.create!(
        agency: @agency,
        code: "w9",
        name: "W-9",
        category: "tax_form",
        verification_required: true,
        status: "active"
      )
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "Pat Doc", status: "active")
    PersonProfile.create!(party: @party, first_name: "Pat", last_name: "Doc")
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

    post login_path, params: { email: @user.email, password: "password1234" }
    follow_redirect!
  end

  test "new prefills from intake params when requirement applies to engagement" do
    get new_admin_document_record_path(
      team_member_id: @tm.id,
      engagement_id: @eng.id,
      document_requirement_id: @req.id,
      document_type_id: @dtype.id,
      intake: "missing_requirement"
    )
    assert_response :success
    assert_includes @response.body, "Add missing document"
    assert_includes @response.body, "Satisfying"
    assert_includes @response.body, "W-9"

    assert_select "input[name='document_record[submitted_on]'][value='#{Date.current.iso8601}']"
    assert_select "input[name='document_requirement_id'][value='#{@req.id}']"
    assert_select "input[name='document_intake_mode'][value='missing_requirement']"
  end

  test "new rejects requirement that does not apply to engagement" do
    ic_req =
      DocumentRequirement.create!(
        agency: @agency,
        document_type: @dtype,
        requirement_scope: "engagement",
        relationship_type: "individual_contractor",
        status: "active",
        required: true,
        verification_required: false
      )

    get new_admin_document_record_path(
      team_member_id: @tm.id,
      engagement_id: @eng.id,
      document_requirement_id: ic_req.id,
      intake: "missing_requirement"
    )
    assert_response :success
    assert_includes @response.body, "does not apply to the selected engagement"
    refute_includes @response.body, "Satisfying"
  end

  test "new ignores document_requirement_id from another agency" do
    other = Agency.create!(name: "OtherAg", code: "oa#{SecureRandom.hex(4)}")
    other_dt =
      DocumentType.create!(
        agency: other,
        code: "other",
        name: "Other Type",
        category: "tax_form",
        status: "active"
      )
    other_req =
      DocumentRequirement.create!(
        agency: other,
        document_type: other_dt,
        requirement_scope: "engagement",
        relationship_type: "employee",
        status: "active",
        required: true,
        verification_required: false
      )

    get new_admin_document_record_path(
      team_member_id: @tm.id,
      engagement_id: @eng.id,
      document_requirement_id: other_req.id,
      intake: "missing_requirement"
    )
    assert_response :success
    refute_includes @response.body, "Other Type"
    refute_includes @response.body, "Satisfying"
  end

  test "new warns and aligns document type when query type mismatches requirement" do
    other_dtype =
      DocumentType.create!(
        agency: @agency,
        code: "i9",
        name: "I-9",
        category: "tax_form",
        status: "active"
      )

    get new_admin_document_record_path(
      team_member_id: @tm.id,
      engagement_id: @eng.id,
      document_requirement_id: @req.id,
      document_type_id: other_dtype.id,
      intake: "missing_requirement"
    )
    assert_response :success
    assert_includes @response.body, "Document type adjusted to match the selected requirement"
    assert_select "select[name='document_record[document_type_id]'] option[selected][value='#{@dtype.id}']"
  end
end

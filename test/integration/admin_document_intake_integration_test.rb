# frozen_string_literal: true

require "test_helper"

class AdminDocumentIntakeIntegrationTest < ActionDispatch::IntegrationTest
  test "prefilled new document record from missing intake preserves requirement and lists guided actions" do
    agency = Agency.create!(name: "DockInt", code: "dc#{SecureRandom.hex(4)}")
    user = User.create!(
      email: "dock#{SecureRandom.hex(4)}@example.com",
      password: "password1234",
      password_confirmation: "password1234"
    )
    UserAgency.create!(user: user, agency: agency)

    dtype =
      DocumentType.create!(
        agency: agency,
        code: "w9",
        name: "Contractor W-9",
        category: "tax_form",
        verification_required: true,
        status: "active"
      )
    party = Party.create!(agency: agency, party_type: "person", display_name: "Dock Pat", status: "active")
    PersonProfile.create!(party: party, first_name: "Dock", last_name: "Pat")
    party.reload
    tm = TeamMember.create!(agency: agency, party: party, status: "active")
    req =
      DocumentRequirement.create!(
        agency: agency,
        document_type: dtype,
        requirement_scope: "engagement",
        relationship_type: "employee",
        status: "active",
        required: true,
        verification_required: true
      )
    eng =
      Engagement.create!(
        agency: agency,
        team_member: tm,
        relationship_type: "employee",
        title: "Rep",
        status: "active",
        start_on: Date.current
      )

    post login_path, params: { email: user.email, password: "password1234" }
    follow_redirect!

    get admin_team_member_team360_path(tm, params: { engagement_id: eng.id })
    assert_response :success
    assert_match(/Add (Contractor )?W-9/, @response.body)

    intake_url =
      new_admin_document_record_path(
        team_member_id: tm.id,
        engagement_id: eng.id,
        document_type_id: dtype.id,
        document_requirement_id: req.id,
        intake: "missing_requirement",
        return_to: "/admin/foo",
        team360_return_to: "/admin/bar"
      )

    get intake_url
    assert_response :success
    assert_includes @response.body, "Add missing document"
    assert_select "input[name='document_requirement_id'][value='#{req.id}']"
  end
end

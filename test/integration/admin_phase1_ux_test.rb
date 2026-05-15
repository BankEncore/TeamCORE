# frozen_string_literal: true

require "test_helper"

class AdminPhase1UxTest < ActionDispatch::IntegrationTest
  PASSWORD = "integration-test-password-0123456789"

  setup do
    @agency_a = Agency.create!(code: "ux_agency_a", name: "UX Agency A", status: "active")
    @agency_b = Agency.create!(code: "ux_agency_b", name: "UX Agency B", status: "active")

    @user = User.create!(
      email: "ux_admin@example.test",
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
    UserAgency.create!(user: @user, agency: @agency_a)

    @department = Department.create!(
      agency: @agency_a,
      code: "ux_dept",
      name: "UX Department",
      status: "active"
    )
    @location = Location.create!(
      agency: @agency_a,
      code: "ux_loc",
      name: "UX Location",
      location_type: "office",
      status: "active"
    )
    @team = Team.create!(
      agency: @agency_a,
      code: "ux_team",
      name: "UX Team",
      department: @department,
      location: @location,
      status: "active"
    )

    @party_supervisor = party_with_person!("ux_supervisor", "Sid", "Supervisor")
    @tm_supervisor = TeamMember.create!(agency: @agency_a, party: @party_supervisor, status: "active")
    @eng_supervisor = Engagement.create!(
      agency: @agency_a,
      team_member: @tm_supervisor,
      relationship_type: "employee",
      status: "active",
      start_on: Date.new(2024, 1, 1)
    )

    @party_supervisee = party_with_person!("ux_supervisee", "Robin", "Direct")
    @tm_supervisee = TeamMember.create!(agency: @agency_a, party: @party_supervisee, status: "active")
    @eng_supervisee = Engagement.create!(
      agency: @agency_a,
      team_member: @tm_supervisee,
      relationship_type: "employee",
      status: "active",
      start_on: Date.new(2024, 1, 1)
    )

    @party_draft = party_with_person!("ux_draft_party", "Drafty", "Person")
    @tm_draft = TeamMember.create!(agency: @agency_a, party: @party_draft, status: "active")
    @engagement_draft = Engagement.create!(
      agency: @agency_a,
      team_member: @tm_draft,
      relationship_type: "employee",
      status: "draft"
    )
  end

  test "guest is redirected from admin to login" do
    get admin_root_url
    assert_redirected_to login_url
    follow_redirect!
    assert_response :success
    assert_select "h1", /sign in/i
  end

  test "authenticated user reaches dashboard" do
    sign_in!

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "h1", /dashboard/i
  end

  test "department create and show happy path" do
    sign_in!

    assert_difference -> { Department.where(agency_id: @agency_a.id).count }, +1 do
      post admin_departments_url, params: {
        department: {
          code: "new_dept",
          name: "New Department",
          description: "",
          status: "active"
        }
      }
    end
    assert_redirected_to %r{/admin/departments/\d+}
    follow_redirect!
    assert_response :success

    dept = Department.find_by!(agency: @agency_a, code: "new_dept")
    assert_select "h1", text: dept.name
  end

  test "cross-agency department access returns not found" do
    dept_b = Department.create!(
      agency: @agency_b,
      code: "other",
      name: "Other Dept",
      status: "active"
    )

    sign_in!
    assert_response :redirect
    follow_redirect!

    patch admin_department_url(dept_b), params: {
      department: { name: "Hacked", code: dept_b.code, status: dept_b.status }
    }
    assert_response :not_found
  end

  test "forbidden agency picker choice is rejected" do
    sign_in!

    patch admin_agency_context_path,
      params: { agency_id: @agency_b.id.to_s, return_to: admin_root_path }
    assert_response :redirect
    assert_match(%r{/admin/agency_context}, response.redirect_url)
    follow_redirect!
    assert_match(/not available/i, flash[:alert].to_s)
  end

  test "agency picker rejects id for agency with no membership (forged switch)" do
    UserAgency.create!(user: @user, agency: @agency_b)
    agency_c = Agency.create!(code: "ux_lonely", name: "No Membership", status: "active")

    post login_url, params: { email: @user.email, password: PASSWORD }
    follow_redirect!

    patch admin_agency_context_path,
      params: { agency_id: agency_c.id.to_s, return_to: admin_root_path }
    assert_response :redirect
    assert_match(%r{/admin/agency_context}, response.redirect_url)
    follow_redirect!
    assert_match(/not available/i, flash[:alert].to_s)
  end

  test "engagement rejects invalid draft to active status transition" do
    sign_in!

    patch admin_engagement_url(@engagement_draft), params: {
      engagement: {
        status: "active",
        relationship_type: "employee",
        title: "",
        notes: ""
      }
    }
    assert_response :unprocessable_entity
    assert_match(/status/i, @response.body)
  end

  test "placement overlap returns unprocessable entity" do
    sign_in!

    EngagementOrganizationPlacement.create!(
      agency: @agency_a,
      engagement: @eng_supervisee,
      department: @department,
      location: @location,
      team: @team,
      effective_start_on: Date.new(2024, 1, 1),
      effective_end_on: nil
    )

    assert_no_difference -> { EngagementOrganizationPlacement.count } do
      post admin_engagement_placements_url(@eng_supervisee), params: {
        engagement_organization_placement: {
          department_id: @department.id,
          location_id: @location.id,
          team_id: @team.id,
          effective_start_on: Date.new(2024, 6, 1),
          effective_end_on: "",
          notes: ""
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/overlap/i, @response.body)
  end

  test "supervision creates with valid employee supervisor" do
    sign_in!

    assert_difference -> { EngagementSupervisionAssignment.count }, +1 do
      post admin_engagement_supervision_assignments_url(@eng_supervisee), params: {
        engagement_supervision_assignment: {
          supervisor_engagement_id: @eng_supervisor.id,
          relationship_type: "primary_reports_to",
          effective_start_on: Date.new(2024, 2, 1),
          effective_end_on: "",
          notes: ""
        }
      }
    end
    assert_response :redirect
  end

  test "supervision rejects self supervisor edge" do
    sign_in!

    assert_no_difference -> { EngagementSupervisionAssignment.count } do
      post admin_engagement_supervision_assignments_url(@eng_supervisee), params: {
        engagement_supervision_assignment: {
          supervisor_engagement_id: @eng_supervisee.id,
          relationship_type: "primary_reports_to",
          effective_start_on: Date.new(2024, 2, 1),
          effective_end_on: "",
          notes: ""
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/own engagement/i, @response.body)
  end

  test "supervision rejects non-employee supervisor" do
    org_party = Party.create!(
      agency: @agency_a,
      party_type: "organization",
      status: "active",
      external_reference: "ux_org_co",
      display_name: "Co Org"
    )
    OrganizationProfile.create!(
      party: org_party,
      legal_name: "Co Org LLC",
      trade_name: "Co Org",
      organization_kind: "contractor_organization"
    )
    org_tm = TeamMember.create!(agency: @agency_a, party: org_party, status: "active")
    bad_sup = Engagement.create!(
      agency: @agency_a,
      team_member: org_tm,
      relationship_type: "contractor_organization",
      status: "active",
      start_on: Date.new(2024, 1, 1)
    )

    sign_in!

    assert_no_difference -> { EngagementSupervisionAssignment.count } do
      post admin_engagement_supervision_assignments_url(@eng_supervisee), params: {
        engagement_supervision_assignment: {
          supervisor_engagement_id: bad_sup.id,
          relationship_type: "primary_reports_to",
          effective_start_on: Date.new(2024, 2, 1),
          effective_end_on: "",
          notes: ""
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/employee/i, @response.body)
  end

  test "person party create persists person profile only" do
    sign_in!

    assert_difference -> { Party.count }, +1 do
      assert_difference -> { PersonProfile.count }, +1 do
        assert_no_difference -> { OrganizationProfile.count } do
          post admin_person_parties_url, params: {
            party: {
              display_name: "Alex Person",
              external_reference: "ux_alex_person",
              notes: "",
              person_profile: {
                first_name: "Alex",
                last_name: "Only"
              }
            }
          }
        end
      end
    end
    assert_response :redirect
    party = Party.find_by!(agency: @agency_a, external_reference: "ux_alex_person")
    assert party.person?
    assert_nil OrganizationProfile.find_by(party_id: party.id)
  end

  test "organization party create persists organization profile only" do
    sign_in!

    assert_difference -> { Party.count }, +1 do
      assert_difference -> { OrganizationProfile.count }, +1 do
        assert_no_difference -> { PersonProfile.count } do
          post admin_organization_parties_url, params: {
            party: {
              display_name: "Brick LLC",
              external_reference: "ux_brick_org",
              notes: "",
              organization_profile: {
                legal_name: "Brick LLC",
                trade_name: "Brick",
                organization_kind: "vendor"
              }
            }
          }
        end
      end
    end
    assert_response :redirect
    party = Party.find_by!(agency: @agency_a, external_reference: "ux_brick_org")
    assert party.organization?
    assert_nil PersonProfile.find_by(party_id: party.id)
  end

  test "multi-agency operator is sent to agency context until a valid agency is chosen" do
    UserAgency.create!(user: @user, agency: @agency_b)

    post login_url, params: { email: @user.email, password: PASSWORD }
    assert_redirected_to admin_agency_context_url
  end

  private

  def party_with_person!(external_reference, first_name, last_name)
    party = Party.create!(
      agency: @agency_a,
      party_type: "person",
      status: "active",
      external_reference: external_reference,
      display_name: "#{first_name} #{last_name}",
      notes: ""
    )
    PersonProfile.create!(party: party, first_name: first_name, last_name: last_name)
    party
  end

  def sign_in!
    post login_url, params: { email: @user.email, password: PASSWORD }
  end
end

# frozen_string_literal: true

module Phase4TestHelper
  PASSWORD = "password1234"

  def p4_agency_user!
    agency = Agency.create!(name: "Phase4 #{SecureRandom.hex(3)}", code: "p4#{SecureRandom.hex(4)}")
    user = User.create!(
      email: "p4u#{SecureRandom.hex(5)}@ex.test",
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
    UserAgency.create!(user:, agency:)
    [ agency, user ]
  end

  def p4_person_party!(agency, first: "Pat", last: "Person")
    party = Party.create!(agency:, party_type: "person", display_name: "#{first} #{last}")
    PersonProfile.create!(party:, first_name: first, last_name: last)
    party.reload
  end

  def p4_org_party_contractor!(agency)
    party = Party.create!(agency:, party_type: "organization", display_name: "Contractor Co")
    OrganizationProfile.create!(
      party:,
      legal_name: "CC LLC",
      trade_name: "CC",
      organization_kind: "contractor_organization"
    )
    party.reload
  end

  def p4_activate!(engagement, start_on: Date.new(2024, 1, 1))
    engagement.update!(status: "pending") if engagement.status == "draft"
    engagement.update!(status: "active", start_on:)
    engagement
  end

  def p4_active_employee!(agency, start_on: Date.new(2024, 1, 1))
    party = p4_person_party!(agency)
    tm = TeamMember.create!(agency:, party:)
    eng = Engagement.create!(agency:, team_member: tm, relationship_type: "employee", status: "pending")
    p4_activate!(eng, start_on:)
    { party:, team_member: tm, engagement: eng }
  end

  def p4_active_ic!(agency, start_on: Date.new(2024, 1, 1))
    party = p4_person_party!(agency, first: "Indy", last: "Contractor")
    tm = TeamMember.create!(agency:, party:)
    eng = Engagement.create!(agency:, team_member: tm, relationship_type: "individual_contractor", status: "pending")
    p4_activate!(eng, start_on:)
    { party:, team_member: tm, engagement: eng }
  end

  def p4_active_contractor_org!(agency, start_on: Date.new(2024, 1, 1))
    party = p4_org_party_contractor!(agency)
    tm = TeamMember.create!(agency:, party:)
    eng = Engagement.create!(agency:, team_member: tm, relationship_type: "contractor_organization", status: "pending")
    p4_activate!(eng, start_on:)
    { party:, team_member: tm, engagement: eng }
  end

  def p4_active_subcontractor!(agency, start_on: Date.new(2024, 1, 1))
    party = p4_person_party!(agency, first: "Sub", last: "Person")
    tm = TeamMember.create!(agency:, party:)
    eng = Engagement.create!(agency:, team_member: tm, relationship_type: "subcontractor", status: "pending")
    p4_activate!(eng, start_on:)
    { party:, team_member: tm, engagement: eng }
  end

  def p4_commission_plan!(agency, name: "Commission plan", rate_bps: 1000, minimum_cents: nil)
    CompensationPlan.create!(
      agency:,
      name:,
      plan_type: "commission_only",
      status: "active",
      default_commission_rate_bps: rate_bps,
      minimum_commission_basis: minimum_cents ? "fixed_amount" : nil,
      minimum_commission_amount_cents: minimum_cents,
      recovery_rule: minimum_cents ? "recover_from_excess_commission" : nil
    )
  end

  def p4_assign_plan!(agency:, engagement:, plan:, start_on: Date.new(2024, 1, 1))
    CompensationPlanAssignment.create!(
      agency:,
      engagement:,
      compensation_plan: plan,
      effective_start_on: start_on,
      snapshot_plan_name: plan.name,
      snapshot_plan_type: plan.plan_type,
      snapshot_commission_rate_bps: plan.default_commission_rate_bps,
      snapshot_minimum_basis: plan.minimum_commission_basis,
      snapshot_minimum_amount_cents: plan.minimum_commission_amount_cents,
      snapshot_recovery_rule: plan.recovery_rule
    )
  end
end

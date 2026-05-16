# frozen_string_literal: true

# Idempotent baseline organization data for development and demos (TC-01.11).
#
# Acceptance checklist (audit):
# - Baseline agency: "Example Agency" (code: example).
# - Baseline departments/locations/teams match epic TC-01.11 naming (generic demo labels).
# - TC-06: demo document types, requirements, and sample records (evaluator-ready).
# - Workforce financials demo (`db/seeds/phase4.rb`): compensation, revenue/commission, charges, settlement.
# - Intentionally generic — not modeled on a single real-world company name or structure.
#
# Run: bin/rails db:seed   (inside Docker per project README if applicable)

agency = Agency.find_or_initialize_by(code: "example")
agency.assign_attributes(name: "Example Agency", status: "active")
agency.save!

department_defs = [
  { code: "admin", name: "Administration" },
  { code: "operations", name: "Operations" },
  { code: "sales", name: "Sales" },
  { code: "accounting", name: "Accounting" },
  { code: "contractor_relations", name: "Contractor Relations" }
]

departments_by_code = department_defs.each_with_object({}) do |row, h|
  d = Department.find_or_initialize_by(agency:, code: row[:code])
  d.assign_attributes(name: row[:name], description: nil, status: "active")
  d.save!
  h[row[:code]] = d
end

location_defs = [
  { code: "main_office", name: "Main Office", location_type: "office" },
  { code: "remote", name: "Remote", location_type: "remote" },
  { code: "virtual", name: "Virtual", location_type: "virtual" }
]

locations_by_code = location_defs.each_with_object({}) do |row, h|
  loc = Location.find_or_initialize_by(agency:, code: row[:code])
  loc.assign_attributes(
    name: row[:name],
    location_type: row[:location_type],
    timezone: nil,
    description: nil,
    status: "active"
  )
  loc.save!
  h[row[:code]] = loc
end

teams = [
  { code: "employee_operations", name: "Employee Operations", department: "operations", location: "main_office" },
  { code: "contractor_support", name: "Contractor Support", department: "contractor_relations", location: "virtual" },
  { code: "payroll_review", name: "Payroll Review", department: "accounting", location: "main_office" },
  { code: "settlement_review", name: "Settlement Review", department: "accounting", location: "main_office" }
]

teams.each do |row|
  t = Team.find_or_initialize_by(agency:, code: row[:code])
  dept = departments_by_code[row[:department]]
  loc = locations_by_code[row[:location]]
  t.assign_attributes(
    name: row[:name],
    department: dept,
    location: loc,
    description: nil,
    status: "active"
  )
  t.save!
end

# Identity & party substrate (TC-02.13) — generic demo actors for TC-03+.
agency = Agency.find_by!(code: "example")

jane_party = Party.find_or_initialize_by(agency:, external_reference: "demo_jane_employee")
jane_party.assign_attributes(party_type: "person", status: "active")
jane_party.save!
PersonProfile.find_or_initialize_by(party: jane_party).tap do |pp|
  pp.assign_attributes(first_name: "Jane", last_name: "Employee")
  pp.save!
end
jane_party.reload

robert_party = Party.find_or_initialize_by(agency:, external_reference: "demo_robert_contractor")
robert_party.assign_attributes(party_type: "person", status: "active")
robert_party.save!
PersonProfile.find_or_initialize_by(party: robert_party).tap do |pp|
  pp.assign_attributes(first_name: "Robert", last_name: "Contractor")
  pp.save!
end
robert_party.reload

maria_party = Party.find_or_initialize_by(agency:, external_reference: "demo_maria_subcontractor")
maria_party.assign_attributes(party_type: "person", status: "active")
maria_party.save!
PersonProfile.find_or_initialize_by(party: maria_party).tap do |pp|
  pp.assign_attributes(first_name: "Maria", last_name: "Subcontractor")
  pp.save!
end
maria_party.reload

sam_party = Party.find_or_initialize_by(agency:, external_reference: "demo_sam_contact")
sam_party.assign_attributes(party_type: "person", status: "active")
sam_party.save!
PersonProfile.find_or_initialize_by(party: sam_party).tap do |pp|
  pp.assign_attributes(first_name: "Sam", last_name: "Contact")
  pp.save!
end
sam_party.reload

contractor_org_party = Party.find_or_initialize_by(agency:, external_reference: "demo_contractor_organization")
contractor_org_party.assign_attributes(party_type: "organization", status: "active")
contractor_org_party.save!
OrganizationProfile.find_or_initialize_by(party: contractor_org_party).tap do |op|
  op.assign_attributes(
    legal_name: "Example Contractor Organization LLC",
    trade_name: "Example Contractor Organization",
    organization_kind: "contractor_organization"
  )
  op.save!
end
contractor_org_party.reload

vendor_party = Party.find_or_initialize_by(agency:, external_reference: "demo_vendor_organization")
vendor_party.assign_attributes(party_type: "organization", status: "active")
vendor_party.save!
OrganizationProfile.find_or_initialize_by(party: vendor_party).tap do |op|
  op.assign_attributes(
    legal_name: "Example Vendor Organization Inc",
    trade_name: "Example Vendor Organization",
    organization_kind: "vendor"
  )
  op.save!
end
vendor_party.reload

[ jane_party, robert_party, contractor_org_party ].each do |p|
  tm = TeamMember.find_or_initialize_by(agency:, party: p)
  tm.assign_attributes(status: "active")
  tm.save!
end

# TC-03 engagement lifecycle demos (Jane employee, Robert IC, contractor org shell).
demo_start_on = Date.new(2024, 1, 1)
jane_tm = TeamMember.find_by!(agency:, party: jane_party)
robert_tm = TeamMember.find_by!(agency:, party: robert_party)
contractor_org_tm = TeamMember.find_by!(agency:, party: contractor_org_party)

jane_eng = Engagement.find_or_initialize_by(agency:, team_member: jane_tm, relationship_type: "employee")
if jane_eng.new_record?
  jane_eng.status = "draft"
  jane_eng.save!
end
unless jane_eng.status == "active"
  jane_eng.update!(status: "pending") if jane_eng.status == "draft"
  jane_eng.update!(status: "active", start_on: demo_start_on)
end

robert_eng = Engagement.find_or_initialize_by(
  agency:,
  team_member: robert_tm,
  relationship_type: "individual_contractor"
)
if robert_eng.new_record?
  robert_eng.status = "draft"
  robert_eng.save!
end
unless robert_eng.status == "active"
  robert_eng.update!(status: "pending") if robert_eng.status == "draft"
  robert_eng.update!(status: "active", start_on: demo_start_on)
end

co_eng = Engagement.find_or_initialize_by(
  agency:,
  team_member: contractor_org_tm,
  relationship_type: "contractor_organization"
)
if co_eng.new_record?
  co_eng.status = "draft"
  co_eng.save!
end
unless co_eng.status == "active"
  co_eng.update!(status: "pending") if co_eng.status == "draft"
  co_eng.update!(status: "active", start_on: demo_start_on)
end

ops_team = Team.find_by!(agency:, code: "employee_operations")
contractor_team = Team.find_by!(agency:, code: "contractor_support")
dept_ops = departments_by_code["operations"]
loc_main = locations_by_code["main_office"]
loc_virtual = locations_by_code["virtual"]
dept_cr = departments_by_code["contractor_relations"]

EngagementOrganizationPlacement.find_or_initialize_by(
  engagement: jane_eng,
  effective_start_on: demo_start_on
).tap do |p|
  p.assign_attributes(department: dept_ops, location: loc_main, team: ops_team)
  p.save!
end

EngagementOrganizationPlacement.find_or_initialize_by(
  engagement: robert_eng,
  effective_start_on: demo_start_on
).tap do |p|
  p.assign_attributes(department: dept_cr, location: loc_virtual, team: contractor_team)
  p.save!
end

EngagementOrganizationPlacement.find_or_initialize_by(
  engagement: co_eng,
  effective_start_on: demo_start_on
).tap do |p|
  p.assign_attributes(department: dept_cr, location: loc_virtual, team: contractor_team)
  p.save!
end

EngagementSupervisionAssignment.find_or_initialize_by(
  engagement: robert_eng,
  supervisor_engagement: jane_eng,
  relationship_type: "primary_reports_to",
  effective_start_on: demo_start_on
).tap do |s|
  s.save! if s.new_record? || s.changed?
end

PartyRelationship.where(
  agency:,
  source_party: contractor_org_party,
  target_party: sam_party,
  relationship_type: "primary_contact"
).first_or_create!(status: "active")

PartyRelationship.where(
  agency:,
  source_party: contractor_org_party,
  target_party: maria_party,
  relationship_type: "subcontractor"
).first_or_create!(status: "active")

# TC-05.08 — Promoted subcontractor (Alex): same PartyRelationship spine plus workforce row.
alex_party = Party.find_or_initialize_by(agency:, external_reference: "demo_alex_subcontractor_promoted")
alex_party.assign_attributes(party_type: "person", status: "active")
alex_party.save!
PersonProfile.find_or_initialize_by(party: alex_party).tap do |pp|
  pp.assign_attributes(first_name: "Alex", last_name: "PromotedSub")
  pp.save!
end
alex_party.reload

PartyRelationship.where(
  agency:,
  source_party: contractor_org_party,
  target_party: alex_party,
  relationship_type: "subcontractor"
).first_or_create!(status: "active")

alex_tm = TeamMember.find_or_initialize_by(agency:, party: alex_party)
alex_tm.assign_attributes(status: "active")
alex_tm.save!

alex_sub_eng = Engagement.find_or_initialize_by(
  agency:,
  team_member: alex_tm,
  relationship_type: "subcontractor"
)
if alex_sub_eng.new_record?
  alex_sub_eng.status = "draft"
  alex_sub_eng.save!
end

# TC-04.12 — Engagement status examples (pending / suspended / ended).
[
  [ "demo_alex_pending_employee", "Alex", "PendingEmployee" ],
  [ "demo_taylor_suspended_employee", "Taylor", "SuspendedEmployee" ],
  [ "demo_casey_ended_employee", "Casey", "EndedEmployee" ]
].each do |external_reference, first_name, last_name|
  party = Party.find_or_initialize_by(agency:, external_reference:)
  party.assign_attributes(party_type: "person", status: "active")
  party.save!
  PersonProfile.find_or_initialize_by(party:).tap do |pp|
    pp.assign_attributes(first_name:, last_name:)
    pp.save!
  end
  party.reload

  tm = TeamMember.find_or_initialize_by(agency:, party:)
  tm.assign_attributes(status: "active")
  tm.save!

  eng = Engagement.find_or_initialize_by(agency:, team_member: tm, relationship_type: "employee")
  case external_reference
  when "demo_alex_pending_employee"
    if eng.new_record?
      eng.status = "pending"
      eng.save!
    elsif eng.status == "draft"
      eng.update!(status: "pending")
    end
  when "demo_taylor_suspended_employee"
    if eng.new_record?
      eng.status = "draft"
      eng.save!
    end
    eng.update!(status: "pending") if eng.status == "draft"
    eng.update!(status: "active", start_on: demo_start_on) unless eng.status == "suspended"
    eng.update!(status: "suspended") if eng.status == "active"
  when "demo_casey_ended_employee"
    if eng.new_record?
      eng.status = "draft"
      eng.save!
    end
    eng.update!(status: "pending") if eng.status == "draft"
    if %w[pending active].include?(eng.status)
      eng.update!(status: "active", start_on: demo_start_on) if eng.status == "pending"
      end_d = demo_start_on + 6.months
      eng.update!(status: "ended", end_on: end_d)
    end
  end
end

# Suspended individual contractor (TC-04.12) — separate from Robert’s active IC path.
riley_party = Party.find_or_initialize_by(agency:, external_reference: "demo_riley_suspended_ic")
riley_party.assign_attributes(party_type: "person", status: "active")
riley_party.save!
PersonProfile.find_or_initialize_by(party: riley_party).tap do |pp|
  pp.assign_attributes(first_name: "Riley", last_name: "SuspendedIC")
  pp.save!
end
riley_party.reload
riley_tm = TeamMember.find_or_initialize_by(agency:, party: riley_party)
riley_tm.assign_attributes(status: "active")
riley_tm.save!

riley_eng = Engagement.find_or_initialize_by(
  agency:,
  team_member: riley_tm,
  relationship_type: "individual_contractor"
)
if riley_eng.new_record?
  riley_eng.status = "draft"
  riley_eng.save!
end
riley_eng.update!(status: "pending") if riley_eng.status == "draft"
riley_eng.update!(status: "active", start_on: demo_start_on) unless riley_eng.status == "suspended"
riley_eng.update!(status: "suspended") if riley_eng.status == "active"

EngagementOrganizationPlacement.find_or_initialize_by(
  engagement: riley_eng,
  effective_start_on: demo_start_on
).tap do |p|
  p.assign_attributes(department: dept_cr, location: loc_virtual, team: contractor_team)
  p.save!
end

# Phase 1 admin — demo operators ( bcrypt + membership; GH-99 ).
admin_pw = ENV.fetch("ADMIN_PASSWORD", "changeme")
admin_user = User.find_or_initialize_by(email: "admin@example.com")
admin_user.password = admin_pw
admin_user.password_confirmation = admin_pw
admin_user.save!

UserAgency.where(user: admin_user, agency: agency).first_or_create!

second_agency = Agency.find_or_initialize_by(code: "example_secondary")
second_agency.assign_attributes(name: "Example Agency Secondary", status: "active")
second_agency.save!
UserAgency.where(user: admin_user, agency: second_agency).first_or_create!

# TC-06 — document configuration & readiness (issue #7)
# Hub: docs/domain/documents-compliance.md
# TC-09 — contractor classification support applicability (docs/domain/contractor-classification-support.md):
# Tax/agreement requirements are scoped to contractor-class engagement types only, not relationship_type "any".
w9_type = DocumentType.find_or_initialize_by(agency:, code: "w9")
w9_type.assign_attributes(
  name: "W-9",
  description: "Tax classification (demo / not legal advice).",
  category: "tax_form",
  requires_expiration_date: false,
  default_expiring_soon_days: nil,
  verification_required: true,
  status: "active"
)
w9_type.save!

contract_agreement_type = DocumentType.find_or_initialize_by(agency:, code: "contractor_services_agreement")
contract_agreement_type.assign_attributes(
  name: "Contractor services agreement",
  description: "Master contractor agreement (demo).",
  category: "contractor_agreement",
  requires_expiration_date: true,
  default_expiring_soon_days: 30,
  verification_required: true,
  status: "active"
)
contract_agreement_type.save!

handbook_type = DocumentType.find_or_initialize_by(agency:, code: "employee_handbook_ack")
handbook_type.assign_attributes(
  name: "Employee handbook acknowledgment",
  description: "Handbook receipt / attestation (demo).",
  category: "employee_agreement",
  requires_expiration_date: false,
  default_expiring_soon_days: nil,
  verification_required: false,
  status: "active"
)
handbook_type.save!

# Retire legacy engagement / team_member W-9 rows scoped to "any" (TC-09-D08).
DocumentRequirement.where(agency:, document_type: w9_type, requirement_scope: "engagement", relationship_type: "any")
  .update_all(status: "inactive")
DocumentRequirement.where(agency:, document_type: w9_type, requirement_scope: "team_member", relationship_type: "any")
  .update_all(status: "inactive")

%w[individual_contractor contractor_organization subcontractor].each do |rel|
  DocumentRequirement.find_or_initialize_by(
    agency:,
    document_type: w9_type,
    requirement_scope: "engagement",
    relationship_type: rel
  ).tap do |req|
    req.assign_attributes(
      name: "W-9 on file",
      required: true,
      verification_required: true,
      expiration_required: false,
      status: "active"
    )
    req.save!
  end

  DocumentRequirement.find_or_initialize_by(
    agency:,
    document_type: w9_type,
    requirement_scope: "team_member",
    relationship_type: rel
  ).tap do |req|
    req.assign_attributes(
      name: "Team member W-9 (identity scope)",
      required: false,
      verification_required: true,
      expiration_required: false,
      status: "active"
    )
    req.save!
  end

  DocumentRequirement.find_or_initialize_by(
    agency:,
    document_type: contract_agreement_type,
    requirement_scope: "engagement",
    relationship_type: rel
  ).tap do |req|
    req.assign_attributes(
      name: "Executed contractor agreement",
      required: true,
      verification_required: true,
      expiration_required: true,
      expiring_soon_days: 45,
      status: "active"
    )
    req.save!
  end
end

DocumentRequirement.find_or_initialize_by(
  agency:,
  document_type: handbook_type,
  requirement_scope: "engagement",
  relationship_type: "employee"
).tap do |req|
  req.assign_attributes(
    name: "Handbook acknowledgment",
    description: "Employee acknowledgment (demo).",
    required: true,
    verification_required: false,
    expiration_required: false,
    status: "active"
  )
  req.save!
end

vdate = Date.new(2024, 2, 1)

# Jane employee — handbook only (contractor tax/agreement requirements do not apply — TC-09).
jane_handbook = DocumentRecord.find_or_initialize_by(
  agency:,
  document_type: handbook_type,
  engagement: jane_eng,
  team_member: jane_tm
)
jane_handbook.assign_attributes(
  filename: "handbook-ack.html",
  content_type: "text/html",
  byte_size: 256,
  display_name: "Handbook acknowledgment",
  status: "submitted",
  submitted_on: vdate,
  storage_key: nil
)
jane_handbook.save!

# Robert IC — pending verification on agreement (expires in demo future)
robert_agreement = DocumentRecord.find_or_initialize_by(
  agency:,
  document_type: contract_agreement_type,
  engagement: robert_eng,
  team_member: robert_tm
)
robert_agreement.assign_attributes(
  filename: "agreement.pdf",
  content_type: "application/pdf",
  byte_size: 24_000,
  display_name: "Services agreement",
  status: "submitted",
  submitted_on: vdate,
  issued_on: vdate,
  expires_on: demo_start_on + 2.years,
  storage_key: "seed/agreement-robert"
)
robert_agreement.save!

# Workforce financials — compensation, revenue/commission, charges, settlement (see db/seeds/phase4.rb)
load Rails.root.join("db/seeds/phase4.rb")

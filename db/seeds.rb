# frozen_string_literal: true

# Idempotent baseline organization data for development and demos (TC-01.11).
#
# Acceptance checklist (audit):
# - Baseline agency: "Example Agency" (code: example).
# - Baseline departments/locations/teams match epic TC-01.11 naming (generic demo labels).
# - Supports TC-03 engagement placement smoke tests (ops vs contractor-aligned teams &
#   main_office / remote / virtual locations for employee vs contractor demos).
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

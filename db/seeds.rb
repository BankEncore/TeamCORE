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

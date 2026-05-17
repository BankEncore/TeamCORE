# frozen_string_literal: true

# Global catalog (TC-23a). Migrations insert these on `db:migrate`, but `db:schema:load`
# leaves the table empty — seed before any Agency is saved so LeaveType defaults can resolve pec IDs.
PAYROLL_EARNING_CODE_SEEDS = [
  { code: "REG", category: "worked_regular", name: "Regular worked hours", position: 10 },
  { code: "OT", category: "worked_overtime", name: "Overtime worked hours", position: 20 },
  { code: "PTO", category: "payable_leave", name: "Paid time off", position: 30 },
  { code: "HOL", category: "payable_leave", name: "Holiday leave", position: 40 },
  { code: "SICK", category: "payable_leave", name: "Sick leave", position: 50 }
].freeze

PAYROLL_EARNING_CODE_SEEDS.each do |row|
  PayrollEarningCode.find_or_initialize_by(code: row[:code]).tap do |pec|
    pec.assign_attributes(
      category: row[:category],
      name: row[:name],
      position: row[:position]
    )
    pec.save!
  end
end

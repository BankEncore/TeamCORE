# frozen_string_literal: true

require "test_helper"

class Payroll::PayrollInputAssemblyServiceTest < ActiveSupport::TestCase
  test "assembles REG rows from approved timesheets in pay period" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "Asm-week",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 3, 5))
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: employee,
      work_date: Date.new(2025, 3, 3),
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: employee
    )
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: user).approve!

    batch = Payroll::PayrollInputBatchEnsureDraftService.call(pay_period: pp, actor: user)
    Payroll::PayrollInputAssemblyService.call(batch:, actor: user)

    rows = batch.reload.payroll_input_rows.where(earning_code: "REG")
    assert rows.any?, "expected REG payroll rows"
    assert(rows.all? { |r| r.source_type == "WeeklyTimesheet" })
  end
end

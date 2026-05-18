# frozen_string_literal: true

require "test_helper"

class Payroll::PayrollExportFileBuilderTest < ActiveSupport::TestCase
  test "csv includes canonical headers" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 7, 7),
      end_on: Date.new(2025, 7, 13),
      label: "builder-week",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 7, 8))
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: employee,
      work_date: Date.new(2025, 7, 7),
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: employee
    )
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 7, 7))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: user).approve!

    batch = Payroll::PayrollInputBatchEnsureDraftService.call(pay_period: pp, actor: user)
    Payroll::FinalizePayrollInputBatchService.call(batch:, actor: user)

    csv, = Payroll::PayrollExportFileBuilder.call(batch:, format: "csv", draft: true)
    first = CSV.parse(csv.lines(chomp: true).first, headers: false).first
    assert_equal Payroll::PayrollExportFileBuilder::COLUMN_KEYS, first
  end
end

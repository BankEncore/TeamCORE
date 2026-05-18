# frozen_string_literal: true

require "test_helper"

class Payroll::PayrollInputBatchLifecycleTest < ActiveSupport::TestCase
  test "finalize reverse and supersede draft" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "Life-week",
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
    Payroll::FinalizePayrollInputBatchService.call(batch:, actor: user)
    assert batch.reload.finalized?

    successor = Payroll::ReversePayrollInputBatchService.call(batch:, actor: user, reason: "Correction")
    assert successor.draft?
    assert batch.reload.reversed?
    assert_equal successor.id, batch.superseded_by_batch_id
    assert_equal batch.id, successor.supersedes_batch_id
  end

  test "final export closes pay period and records closure event with batch link" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 4, 7),
      end_on: Date.new(2025, 4, 13),
      label: "Export-week",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 4, 9))
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: employee,
      work_date: Date.new(2025, 4, 7),
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: employee
    )
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 4, 7))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: user).approve!

    batch = Payroll::PayrollInputBatchEnsureDraftService.call(pay_period: pp, actor: user)
    Payroll::FinalizePayrollInputBatchService.call(batch:, actor: user)

    Payroll::MarkPayrollInputBatchExportedService.call(batch:, actor: user, file_format: "csv")

    assert batch.reload.exported?
    assert pp.reload.closed?
    ev = PayPeriodClosureEvent.order(:id).last
    assert_equal PayPeriodClosureEvent::SOURCES.fetch(:payroll_final_export), ev.source
    assert_equal batch.id, ev.payroll_input_batch_id
    assert_equal "closed", ev.event_type
  end
end

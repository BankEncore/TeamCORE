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
    export = batch.payroll_export
    assert export.export_file.attached?
    assert export.content_sha256.present?
    assert_equal batch.id, export.payroll_input_batch_id
    ev = PayPeriodClosureEvent.order(:id).last
    assert_equal PayPeriodClosureEvent::SOURCES.fetch(:payroll_final_export), ev.source
    assert_equal batch.id, ev.payroll_input_batch_id
    assert_equal "closed", ev.event_type
  end

  test "draft payroll export keeps period open and attaches file" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 6, 2),
      end_on: Date.new(2025, 6, 8),
      label: "Draft-export-week",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 6, 3))
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: employee,
      work_date: Date.new(2025, 6, 2),
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: employee
    )
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 6, 2))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: user).approve!

    batch = Payroll::PayrollInputBatchEnsureDraftService.call(pay_period: pp, actor: user)
    Payroll::FinalizePayrollInputBatchService.call(batch:, actor: user)

    Payroll::GenerateDraftPayrollExportService.call(batch:, actor: user, file_format: "csv")

    assert pp.reload.open?
    assert batch.reload.finalized?
    export = batch.source_payroll_exports.order(:export_sequence).last
    assert_not export.is_final?
    assert export.export_file.attached?
    assert export.validation_summary.is_a?(Hash)
  end
end

# frozen_string_literal: true

require "test_helper"

class Payroll::WeeklyTimesheetApprovalTransitionsTest < ActiveSupport::TestCase
  setup do
    @agency, @actor = p4_agency_user!
    @eng = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @monday = Date.new(2025, 3, 3)
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @eng,
      work_date: @monday,
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: @eng
    )
    @sheet = WeeklyTimesheet.find_by!(engagement: @eng, week_start_on: @monday)
    Payroll::TimesheetSubmissionService.call(timesheet: @sheet, role: :employee, actor_engagement: @eng)
    @sheet.reload
  end

  test "approve transitions submitted to approved" do
    Payroll::WeeklyTimesheetApprovalTransitions.new(timesheet: @sheet, actor: @actor).approve!
    assert_equal "approved", @sheet.reload.status
    assert @sheet.approved_at.present?
  end

  test "send_back_to_draft clears submitted_at" do
    Payroll::WeeklyTimesheetApprovalTransitions.new(timesheet: @sheet, actor: @actor).send_back_to_draft!
    @sheet.reload
    assert_equal "draft", @sheet.status
    assert_nil @sheet.submitted_at
  end

  test "reopen_to_draft from approved" do
    Payroll::WeeklyTimesheetApprovalTransitions.new(timesheet: @sheet, actor: @actor).approve!
    Payroll::WeeklyTimesheetApprovalTransitions.new(timesheet: @sheet.reload, actor: @actor).reopen_to_draft!
    assert_equal "draft", @sheet.reload.status
  end
end

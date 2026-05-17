# frozen_string_literal: true

require "test_helper"

class AdminWeeklyTimesheetsTest < ActionDispatch::IntegrationTest
  setup do
    @agency, @user = p4_agency_user!
    @employee_eng = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @monday = Date.new(2025, 3, 3)

    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: @employee_eng
    )
    @sheet = WeeklyTimesheet.find_by!(engagement: @employee_eng, week_start_on: @monday)
    Payroll::TimesheetSubmissionService.call(timesheet: @sheet, role: :employee, actor_engagement: @employee_eng)

    post login_path, params: { email: @user.email, password: Phase4TestHelper::PASSWORD }
    follow_redirect!
  end

  test "approval queue lists submitted timesheets" do
    get admin_weekly_timesheets_path
    assert_response :success
    assert_match(/Submitted/i, response.body)
  end

  test "approve creates audit event and approved status" do
    post approve_admin_weekly_timesheet_path(@sheet.reload)
    assert_redirected_to admin_weekly_timesheet_path(@sheet)

    assert_equal "approved", @sheet.reload.status
    ev = @sheet.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "approved", ev.event_type
    assert_equal @user.id, ev.actor_id
  end

  test "send_back returns sheet to draft with reason in metadata" do
    post send_back_admin_weekly_timesheet_path(@sheet.reload), params: { reason: "Adjust Monday" }
    assert_redirected_to admin_weekly_timesheets_path

    assert_equal "draft", @sheet.reload.status
    ev = @sheet.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "sent_back", ev.event_type
    assert_equal "Adjust Monday", ev.metadata_hash["reason"]
  end
end

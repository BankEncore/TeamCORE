# frozen_string_literal: true

require "test_helper"

class Payroll::TimesheetApprovalServiceTest < ActiveSupport::TestCase
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

  test "approve transitions submitted to approved and records audit event" do
    Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet, actor: @actor).approve!
    assert_equal "approved", @sheet.reload.status
    assert @sheet.approved_at.present?

    ev = @sheet.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "submitted", ev.transition_from
    assert_equal "approved", ev.transition_to
    assert_equal "approved", ev.event_type
    assert_equal @actor, ev.actor
  end

  test "send_back_to_draft clears submitted_at and records transition" do
    Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet, actor: @actor).send_back_to_draft!(reason: "Fix Monday")
    @sheet.reload
    assert_equal "draft", @sheet.status
    assert_nil @sheet.submitted_at

    ev = @sheet.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "submitted", ev.transition_from
    assert_equal "draft", ev.transition_to
    assert_equal "sent_back", ev.event_type
    assert_equal "Fix Monday", ev.metadata_hash["reason"]
  end

  test "send_back supports returned_for_correction disposition" do
    Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet, actor: @actor)
      .send_back_to_draft!(reason: "x", disposition: "returned_for_correction")

    ev = @sheet.reload.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "returned_for_correction", ev.event_type
  end

  test "reopen_to_draft from approved clears approval snapshot and records event" do
    Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet, actor: @actor).approve!
    Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet.reload, actor: @actor).reopen_to_draft!(reason: "post-pay correction")

    assert_equal "draft", @sheet.reload.status
    assert_nil @sheet.approved_at
    assert_nil @sheet.approved_by_id

    ev = @sheet.weekly_timesheet_approval_events.recent_first.first!
    assert_equal "approved", ev.transition_from
    assert_equal "draft", ev.transition_to
    assert_equal "reopened", ev.event_type
    assert_equal "post-pay correction", ev.metadata_hash["reason"]
  end

  test "agency outsider cannot approve" do
    other_agency = Agency.create!(name: "Other TC24 Agency #{SecureRandom.hex(4)}", code: "tc24#{SecureRandom.hex(4)}")
    outsider = User.create!(
      email: "outsider-tc24-#{SecureRandom.hex(4)}@example.com",
      password: Phase4TestHelper::PASSWORD,
      password_confirmation: Phase4TestHelper::PASSWORD
    )
    UserAgency.create!(user: outsider, agency: other_agency)

    assert_raises(Payroll::TimesheetApprovalService::Error) do
      Payroll::TimesheetApprovalService.new(weekly_timesheet: @sheet, actor: outsider).approve!
    end
  end
end

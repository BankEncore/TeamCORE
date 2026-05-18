# frozen_string_literal: true

require "test_helper"

class Payroll::TimesheetFlowTc23Test < ActiveSupport::TestCase
  setup do
    @agency, @admin = p4_agency_user!
    @employee_eng = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @monday = Date.new(2025, 3, 3)
  end

  test "assembly creates draft weekly timesheet aligned to agency workweek" do
    sheet = Payroll::TimesheetAssemblyService.ensure!(@employee_eng, reference_date: @monday)
    assert_equal "draft", sheet.status
    assert_equal Date.new(2025, 3, 3), sheet.week_start_on
    assert_equal Date.new(2025, 3, 9), sheet.week_end_on
  end

  test "employee cannot upsert hours while submitted" do
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: @employee_eng
    )
    sheet = WeeklyTimesheet.find_by!(engagement: @employee_eng, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: @employee_eng)

    assert_raises(Payroll::DailyWorkedHourUpsertService::Error) do
      Payroll::DailyWorkedHourUpsertService.call(
        engagement: @employee_eng,
        work_date: @monday,
        hours: 7,
        source: :employee,
        role: :employee,
        actor_engagement: @employee_eng
      )
    end
  end

  test "payroll_admin can upsert hours while submitted" do
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: @employee_eng
    )
    sheet = WeeklyTimesheet.find_by!(engagement: @employee_eng, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: @employee_eng)

    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 7.5,
      source: :admin,
      role: :payroll_admin,
      actor_engagement: nil
    )
    assert_equal BigDecimal("7.5"), DailyWorkedHour.find_by!(engagement: @employee_eng, work_date: @monday).hours
  end

  test "submission returns weekday missing warnings without failing" do
    sheet = Payroll::TimesheetAssemblyService.ensure!(@employee_eng, reference_date: @monday)
    result = Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: @employee_eng)
    assert_equal "submitted", result.timesheet.status
    assert result.warnings.any? { |w| w.include?("No hours entered") }
  end

  test "overtime presenter marks projected until approved" do
    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 10,
      source: :employee,
      role: :employee,
      actor_engagement: @employee_eng
    )
    # Fill rest of week with zeros... actually OT needs sum > 40 — add 5 days x 10 = 50 -> 10 OT
    Date.new(2025, 3, 3).upto(Date.new(2025, 3, 7)) do |d|
      next if d == @monday

      Payroll::DailyWorkedHourUpsertService.call(
        engagement: @employee_eng,
        work_date: d,
        hours: 10,
        source: :employee,
        role: :employee,
        actor_engagement: @employee_eng
      )
    end

    sheet = WeeklyTimesheet.find_by!(engagement: @employee_eng, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: @employee_eng)
    sheet.reload

    view = Payroll::TimesheetOvertimePresenter.for_timesheet(sheet)
    assert_equal :projected, view.visibility_mode
    assert_operator view.overtime_hours, :>, 0

    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: @admin).approve!
    sheet.reload
    view2 = Payroll::TimesheetOvertimePresenter.for_timesheet(sheet)
    assert_equal :approved, view2.visibility_mode
  end

  test "supervisor can upsert direct report hours when submitted" do
    sup_party = p4_person_party!(@agency, first: "Sam", last: "Super")
    sup_tm = TeamMember.create!(agency: @agency, party: sup_party)
    sup_eng = Engagement.create!(agency: @agency, team_member: sup_tm, relationship_type: "employee", status: "pending")
    p4_activate!(sup_eng, start_on: Date.new(2025, 1, 1))

    EngagementSupervisionAssignment.create!(
      agency: @agency,
      engagement: @employee_eng,
      supervisor_engagement: sup_eng,
      relationship_type: "primary_reports_to",
      effective_start_on: Date.new(2025, 1, 1)
    )

    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 8,
      source: :employee,
      role: :employee,
      actor_engagement: @employee_eng
    )
    sheet = WeeklyTimesheet.find_by!(engagement: @employee_eng, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: @employee_eng)

    Payroll::DailyWorkedHourUpsertService.call(
      engagement: @employee_eng,
      work_date: @monday,
      hours: 8.5,
      source: :supervisor,
      role: :direct_supervisor,
      actor_engagement: sup_eng,
      supervisor_engagement: sup_eng
    )

    assert_equal BigDecimal("8.5"), DailyWorkedHour.find_by!(engagement: @employee_eng, work_date: @monday).hours
  end
end

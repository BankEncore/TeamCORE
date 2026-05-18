# frozen_string_literal: true

require "test_helper"

class Payroll::PayPeriodClosureTc23Test < ActiveSupport::TestCase
  test "blocks close when active employee lacks weekly timesheet rows" do
    agency, user = p4_agency_user!
    p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "Week-block",
      payroll_frequency: "legacy",
      status: "open"
    )

    assert_raises(Payroll::PayPeriodClosureService::Error) do
      Payroll::PayPeriodClosureService.call(pay_period: pp, actor: user)
    end
  end

  test "closes when timesheets exist for intersecting workweeks" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "Week-ok",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 3, 5))
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: user).approve!

    Payroll::PayPeriodClosureService.call(pay_period: pp, actor: user)
    assert pp.reload.closed?
  end

  test "blocks close when timesheet is submitted but not approved" do
    agency, user = p4_agency_user!
    employee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "Week-submitted-only",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::TimesheetAssemblyService.ensure!(employee, reference_date: Date.new(2025, 3, 5))
    sheet = WeeklyTimesheet.find_by!(engagement: employee, week_start_on: Date.new(2025, 3, 3))
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: employee)

    assert_raises(Payroll::PayPeriodClosureService::Error) do
      Payroll::PayPeriodClosureService.call(pay_period: pp, actor: user)
    end
  end
end

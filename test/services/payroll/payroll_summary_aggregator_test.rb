# frozen_string_literal: true

require "test_helper"

class Payroll::PayrollSummaryAggregatorTest < ActiveSupport::TestCase
  test "returns empty summary until time and leave sources exist" do
    agency, = p4_agency_user!
    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 1, 1),
      end_on: Date.new(2025, 1, 15),
      payroll_frequency: "legacy",
      status: "open"
    )
    summary = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp).call
    assert_equal BigDecimal("0"), summary.regular_hours
    assert_equal({}, summary.hours_by_earning_code)
  end

  test "sums approved worked REG and OT for timesheets whose week ends in pay period" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 20),
      payroll_frequency: "legacy",
      status: "open"
    )

    monday = Date.new(2025, 3, 3)
    monday.upto(monday + 4.days) do |d|
      Payroll::DailyWorkedHourUpsertService.call(
        engagement: eng,
        work_date: d,
        hours: 10,
        source: :employee,
        role: :employee,
        actor_engagement: eng
      )
    end

    sheet = WeeklyTimesheet.find_by!(engagement: eng, week_start_on: monday)
    Payroll::TimesheetSubmissionService.call(timesheet: sheet, role: :employee, actor_engagement: eng)
    Payroll::WeeklyTimesheetApprovalTransitions.new(timesheet: sheet.reload, actor: admin).approve!

    summary = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp, engagement: eng).call
    assert_operator summary.overtime_hours, :>, 0
    assert_equal summary.regular_hours + summary.overtime_hours, summary.total_paid_hours
    assert summary.hours_by_earning_code.key?("REG")
    assert summary.hours_by_earning_code.key?("OT")
  end
end

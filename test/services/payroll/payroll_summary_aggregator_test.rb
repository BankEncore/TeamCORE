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
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: admin).approve!

    summary = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp, engagement: eng).call
    assert_operator summary.overtime_hours, :>, 0
    assert_equal summary.regular_hours + summary.overtime_hours, summary.total_paid_hours
    assert summary.hours_by_earning_code.key?("REG")
    assert summary.hours_by_earning_code.key?("OT")
  end

  test "reopened draft timesheet drops approved hours from payroll summary until re-approved" do
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
    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: admin).approve!

    summary_ok = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp, engagement: eng).call
    assert_operator summary_ok.total_paid_hours, :>, 0

    Payroll::TimesheetApprovalService.new(weekly_timesheet: sheet.reload, actor: admin).reopen_to_draft!(reason: "correction")

    summary_after = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp, engagement: eng).call
    assert_equal BigDecimal("0"), summary_after.total_paid_hours
    assert_equal({}, summary_after.hours_by_earning_code)
  end

  test "sums approved paid and unpaid leave days overlapping pay period into buckets" do
    agency, = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]

    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 20),
      payroll_frequency: "legacy",
      status: "open"
    )

    vacation = agency.leave_types.find_by!(code: "VACATION")
    unpaid = agency.leave_types.find_by!(code: "UNPAID")

    req_paid = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "approved")
    LeaveRequestDay.create!(leave_request: req_paid, leave_date: Date.new(2025, 3, 10), hours: 8)
    LeaveRequestDay.create!(leave_request: req_paid, leave_date: Date.new(2025, 3, 25), hours: 4)

    req_unpaid = LeaveRequest.create!(engagement: eng, leave_type: unpaid, status: "approved")
    LeaveRequestDay.create!(leave_request: req_unpaid, leave_date: Date.new(2025, 3, 12), hours: 3)

    summary = Payroll::PayrollSummaryAggregator.new(agency:, pay_period: pp, engagement: eng).call

    assert_equal BigDecimal("8"), summary.paid_leave_hours
    assert_equal BigDecimal("3"), summary.unpaid_leave_hours
    assert_equal BigDecimal("11"), summary.leave_hours

    pec_pto = PayrollEarningCode.find_by!(code: "PTO")
    assert_equal BigDecimal("8"), summary.hours_by_earning_code[pec_pto.code]
  end
end

# frozen_string_literal: true

require "test_helper"

class Payroll::ClosureValidatorsTc23Test < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @employee = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @pay_period = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 3, 3),
      end_on: Date.new(2025, 3, 9),
      label: "TC23-test-week",
      payroll_frequency: "legacy",
      status: "open"
    )
  end

  test "MissingTimesheets blocks when weekly timesheet row absent" do
    result = Payroll::ClosureValidators::MissingTimesheets.call(agency: @agency, pay_period: @pay_period)
    assert result.blocking?
    assert_match(/Missing weekly timesheet/, result.violations.first)
  end

  test "MissingTimesheets passes when timesheet exists for intersecting workweek" do
    Payroll::TimesheetAssemblyService.ensure!(@employee, reference_date: Date.new(2025, 3, 5))
    result = Payroll::ClosureValidators::MissingTimesheets.call(agency: @agency, pay_period: @pay_period)
    refute result.blocking?
  end

  test "PendingApprovals counts submitted overlapping timesheets" do
    sheet = Payroll::TimesheetAssemblyService.ensure!(@employee, reference_date: Date.new(2025, 3, 5))
    sheet.update!(status: "submitted", submitted_at: Time.current)

    result = Payroll::ClosureValidators::PendingApprovals.call(agency: @agency, pay_period: @pay_period)
    assert result.blocking?
    assert_match(/awaiting approval/, result.message)
  end
end

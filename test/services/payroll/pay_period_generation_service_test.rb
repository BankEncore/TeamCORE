# frozen_string_literal: true

require "test_helper"

class Payroll::PayPeriodGenerationServiceTest < ActiveSupport::TestCase
  setup do
    @agency, @user = p4_agency_user!
    @agency.agency_payroll_configuration.update!(
      payroll_frequency: "weekly",
      pay_schedule_anchor_on: Date.new(2024, 1, 1),
      payroll_timezone: "Etc/UTC",
      workweek_starts_on: 1,
      weekly_overtime_threshold_hours: 40
    )
  end

  test "creates weekly periods idempotently" do
    r1 = Payroll::PayPeriodGenerationService.call(
      agency: @agency,
      actor: @user,
      horizon_months_ahead: 3,
      horizon_months_back: 3
    )
    assert_operator r1[:created], :>, 0

    r2 = Payroll::PayPeriodGenerationService.call(
      agency: @agency,
      actor: @user,
      horizon_months_ahead: 3,
      horizon_months_back: 3
    )
    assert_equal 0, r2[:created]
  end
end

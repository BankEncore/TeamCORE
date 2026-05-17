# frozen_string_literal: true

require "test_helper"

class Payroll::PayPeriodClosureServiceTest < ActiveSupport::TestCase
  setup do
    @agency, @user = p4_agency_user!
  end

  test "closes open pay period" do
    pp = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 3, 1),
      end_on: Date.new(2025, 3, 15),
      label: "Mar-A",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::PayPeriodClosureService.call(pay_period: pp, actor: @user)
    pp.reload
    assert pp.closed?
    assert_equal @user, pp.closed_by
    assert pp.closed_at.present?
  end

  test "rejects closing twice" do
    pp = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 4, 1),
      end_on: Date.new(2025, 4, 15),
      label: "Apr-A",
      payroll_frequency: "legacy",
      status: "open"
    )
    Payroll::PayPeriodClosureService.call(pay_period: pp, actor: @user)

    assert_raises(Payroll::PayPeriodClosureService::Error) do
      Payroll::PayPeriodClosureService.call(pay_period: pp.reload, actor: @user)
    end
  end
end

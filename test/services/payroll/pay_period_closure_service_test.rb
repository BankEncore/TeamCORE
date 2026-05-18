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
    ev = PayPeriodClosureEvent.find_by!(pay_period_id: pp.id)
    assert_equal "closed", ev.event_type
    assert_equal PayPeriodClosureEvent::SOURCES.fetch(:admin_manual), ev.source
    assert_not ev.override_validation
  end

  test "override_validation requires override_reason" do
    pp = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 5, 1),
      end_on: Date.new(2025, 5, 15),
      label: "May-A",
      payroll_frequency: "legacy",
      status: "open"
    )

    assert_raises(Payroll::PayPeriodClosureService::Error) do
      Payroll::PayPeriodClosureService.call(
        pay_period: pp,
        actor: @user,
        override_validation: true,
        override_reason: nil
      )
    end
  end

  test "override_validation closes when reason provided" do
    pp = PayPeriod.create!(
      agency: @agency,
      start_on: Date.new(2025, 6, 1),
      end_on: Date.new(2025, 6, 15),
      label: "Jun-A",
      payroll_frequency: "legacy",
      status: "open"
    )

    Payroll::PayPeriodClosureService.call(
      pay_period: pp,
      actor: @user,
      override_validation: true,
      override_reason: "Operational exception approved"
    )
    assert pp.reload.closed?
    ev = PayPeriodClosureEvent.order(:id).last
    assert_equal "override_closed", ev.event_type
    assert ev.override_validation
    assert_equal "Operational exception approved", ev.override_reason
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

# frozen_string_literal: true

require "test_helper"

class PayPeriodTest < ActiveSupport::TestCase
  test "end_on must be on or after start_on" do
    agency, = p4_agency_user!
    pp = PayPeriod.new(
      agency:,
      start_on: Date.new(2024, 2, 10),
      end_on: Date.new(2024, 2, 1)
    )

    assert_not pp.valid?
    assert pp.errors[:end_on].present?
  end

  test "rejects overlapping sibling periods" do
    agency, = p4_agency_user!
    PayPeriod.create!(
      agency:,
      start_on: Date.new(2024, 5, 1),
      end_on: Date.new(2024, 5, 15),
      payroll_frequency: "legacy",
      status: "open"
    )

    overlap = PayPeriod.new(
      agency:,
      start_on: Date.new(2024, 5, 10),
      end_on: Date.new(2024, 5, 25),
      payroll_frequency: "legacy",
      status: "open"
    )
    assert_not overlap.valid?
    assert overlap.errors[:base].present?
  end

  test "closed pay periods reject updates" do
    agency, user = p4_agency_user!
    pp = PayPeriod.create!(
      agency:,
      start_on: Date.new(2024, 9, 1),
      end_on: Date.new(2024, 9, 15),
      payroll_frequency: "legacy",
      status: "open"
    )
    Payroll::PayPeriodClosureService.call(pay_period: pp, actor: user)

    pp.reload.label = "changed"
    assert_not pp.save
    assert pp.errors[:base].present?
  end
end

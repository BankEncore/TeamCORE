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
end

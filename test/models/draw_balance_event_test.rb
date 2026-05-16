# frozen_string_literal: true

require "test_helper"

class DrawBalanceEventTest < ActiveSupport::TestCase
  test "event_type must be allowlisted" do
    agency, = p4_agency_user!
    ee = p4_active_employee!(agency)

    ev = DrawBalanceEvent.new(
      agency:,
      engagement: ee[:engagement],
      event_type: "not_a_real_event",
      amount_cents: 1
    )

    assert_not ev.valid?
    assert ev.errors[:event_type].present?
  end
end

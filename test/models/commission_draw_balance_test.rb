# frozen_string_literal: true

require "test_helper"

class CommissionDrawBalanceTest < ActiveSupport::TestCase
  test "one balance row per engagement" do
    agency, = p4_agency_user!
    ee = p4_active_employee!(agency)

    CommissionDrawBalance.create!(agency:, engagement: ee[:engagement], balance_cents: 0)

    dup = CommissionDrawBalance.new(agency:, engagement: ee[:engagement], balance_cents: 1)
    assert_not dup.valid?
    assert dup.errors[:engagement_id].present?
  end
end

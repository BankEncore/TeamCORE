# frozen_string_literal: true

require "test_helper"

class ContractorChargeTest < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @ic = p4_active_ic!(@agency)
    @sub = p4_active_subcontractor!(@agency)
  end

  test "allows individual_contractor engagement" do
    ch = ContractorCharge.new(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "onboarding_fee",
      status: "open",
      original_amount_cents: 10_000,
      open_balance_cents: 10_000
    )

    assert ch.valid?, ch.errors.full_messages.join(", ")
  end

  test "rejects subcontractor engagement in Phase 4 MVP" do
    ch = ContractorCharge.new(
      agency: @agency,
      engagement: @sub[:engagement],
      charge_type: "onboarding_fee",
      status: "open",
      original_amount_cents: 10_000,
      open_balance_cents: 10_000
    )

    assert_not ch.valid?
    assert_includes ch.errors[:engagement].join, "contractor"
  end
end

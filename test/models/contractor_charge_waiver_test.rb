# frozen_string_literal: true

require "test_helper"

class ContractorChargeWaiverTest < ActiveSupport::TestCase
  setup do
    @agency, @actor = p4_agency_user!
    @ic = p4_active_ic!(@agency)
    @charge = ContractorCharge.create!(
      agency: @agency,
      engagement: @ic[:engagement],
      charge_type: "onboarding_fee",
      status: "open",
      original_amount_cents: 30_000,
      open_balance_cents: 30_000
    )
  end

  test "reduces open balance on create" do
    ContractorChargeWaiver.create!(
      agency: @agency,
      contractor_charge: @charge,
      actor: @actor,
      amount_cents: 12_000,
      reason: "Goodwill"
    )

    @charge.reload
    assert_equal 18_000, @charge.open_balance_cents
  end
end

# frozen_string_literal: true

require "test_helper"

class OrganizationProfileTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "OP", code: "op#{SecureRandom.hex(4)}")
    @org_party = Party.create!(agency: @agency, party_type: "organization", display_name: "T")
    @organization_profile = OrganizationProfile.create!(
      party: @org_party,
      legal_name: "Legal LLC",
      trade_name: "Trade Co",
      organization_kind: "contractor_organization"
    )
  end

  test "rejects person party" do
    person_party = Party.create!(agency: @agency, party_type: "person", display_name: "P")
    op = OrganizationProfile.new(party: person_party, organization_kind: "vendor")

    assert_not op.valid?
    assert op.errors[:party].present?
  end

  test "organization_kind allow list" do
    @organization_profile.organization_kind = "invalid"
    assert_not @organization_profile.valid?
  end
end

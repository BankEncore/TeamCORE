# frozen_string_literal: true

require "test_helper"

class PersonProfileTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "PP", code: "pp#{SecureRandom.hex(4)}")
    @person_party = Party.create!(agency: @agency, party_type: "person", display_name: "Temp")
  end

  test "rejects organization party" do
    org_party = Party.create!(agency: @agency, party_type: "organization", display_name: "Org")
    OrganizationProfile.create!(party: org_party, legal_name: "L", organization_kind: "vendor")

    profile = PersonProfile.new(party: org_party, first_name: "Nope")

    assert_not profile.valid?
    assert profile.errors[:party].present?
  end

  test "fills party display name when blank after save" do
    p = Party.create!(agency: @agency, party_type: "person", display_name: nil)
    PersonProfile.create!(party: p, preferred_name: "Bob", last_name: "Jones")
    p.reload

    assert_equal "Bob Jones", p.display_name
  end

  test "compose_display_candidate fallback" do
    p_struct = Struct.new(:preferred_name, :last_name, :first_name, keyword_init: true)
    cand = PersonProfile.compose_display_candidate(
      p_struct.new(preferred_name: nil, last_name: "Z", first_name: "Y")
    )
    assert_equal "Y Z", cand
  end
end

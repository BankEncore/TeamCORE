# frozen_string_literal: true

require "test_helper"

class PartyContactMethodTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "PCM", code: "pcm#{SecureRandom.hex(4)}")
    @party = Party.create!(agency: @agency, party_type: "person", display_name: "P")
    PersonProfile.create!(party: @party, first_name: "P", last_name: "Q")
    @party.reload
  end

  test "only one active primary per contact type" do
    PartyContactMethod.create!(
      party: @party,
      contact_type: "email",
      value: "a@example.com",
      is_primary: true,
      status: "active"
    )

    second = PartyContactMethod.new(
      party: @party,
      contact_type: "email",
      value: "b@example.com",
      is_primary: true,
      status: "active"
    )

    assert_not second.valid?
  end
end

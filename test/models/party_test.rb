# frozen_string_literal: true

require "test_helper"

class PartyTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Agency PT", code: "agpt#{SecureRandom.hex(4)}")
  end

  test "blanks display_name is recomposed from profile when identity is complete (TC-02-D05)" do
    p = Party.create!(agency: @agency, party_type: "person", display_name: nil)
    PersonProfile.create!(party: p, first_name: "A", last_name: "B")
    p.reload

    assert_equal "A B", p.display_name

    p.display_name = nil
    assert_predicate p, :valid?
    p.save!

    assert_equal PersonProfile.compose_display_candidate(p.person_profile), p.display_name
    assert_predicate p.reload.display_name, :present?
  end
end

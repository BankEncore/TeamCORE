# frozen_string_literal: true

require "test_helper"

class TeamMemberTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "TM", code: "tm#{SecureRandom.hex(4)}")
    @person_party = Party.create!(agency: @agency, party_type: "person", display_name: "Emp")
    PersonProfile.create!(
      party: @person_party,
      first_name: "Jane",
      last_name: "Employee"
    )
    @person_party.reload
  end

  test "requires complete party identity" do
    draft = Party.create!(agency: @agency, party_type: "person", display_name: "Draft")
    tm = TeamMember.new(agency: @agency, party: draft)

    assert_not tm.valid?
    assert_match(/complete identity/i, tm.errors[:party].join)
  end

  test "rejects cross-agency party" do
    other = Agency.create!(name: "O", code: "o#{SecureRandom.hex(4)}")
    foreign_party = Party.create!(agency: other, party_type: "person", display_name: "F")
    PersonProfile.create!(party: foreign_party, first_name: "F", last_name: "G")

    tm = TeamMember.new(agency: @agency, party: foreign_party)

    assert_not tm.valid?
    assert tm.errors[:party].present?
  end

  test "unique party per agency" do
    TeamMember.create!(agency: @agency, party: @person_party)
    dup = TeamMember.new(agency: @agency, party: @person_party)

    assert_not dup.valid?
  end

  test "normalizes team member number to uppercase" do
    tm = TeamMember.create!(
      agency: @agency,
      party: @person_party,
      team_member_number: "  tm-99  "
    )
    assert_equal "TM-99", tm.team_member_number
  end

  test "unique team_member_number per agency when present" do
    TeamMember.create!(agency: @agency, party: @person_party, team_member_number: "A1")
    other_party = Party.create!(agency: @agency, party_type: "person", display_name: "O")
    PersonProfile.create!(party: other_party, first_name: "O", last_name: "T")

    dup = TeamMember.new(agency: @agency, party: other_party, team_member_number: "a1")

    assert_not dup.valid?
  end
end

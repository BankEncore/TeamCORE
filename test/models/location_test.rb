# frozen_string_literal: true

require "test_helper"

class LocationTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Agency Loc", code: "agl#{SecureRandom.hex(4)}")
  end

  test "requires location_type from allowed list" do
    loc = Location.new(agency: @agency, name: "HQ", code: "HQ1", location_type: "planet")
    assert_not loc.valid?
    assert loc.errors[:location_type].present?
  end

  test "allows nullable timezone and optional description" do
    loc = Location.create!(
      agency: @agency,
      name: "Remote Pool",
      code: "RMT#{SecureRandom.hex(2)}",
      location_type: "remote",
      timezone: nil,
      description: nil
    )
    assert_predicate loc, :persisted?
  end

  test "normalizes code to stripped lowercase before validation" do
    loc = Location.new(agency: @agency, name: "HQ", code: "  Main_OFFICE  ", location_type: "office")
    loc.valid?
    assert_equal "main_office", loc.code
  end

  test "code uniqueness scoped to agency" do
    Location.create!(agency: @agency, name: "Office", code: "MAIN", location_type: "office")
    other_agency = Agency.create!(name: "X", code: "x#{SecureRandom.hex(4)}")
    assert_predicate Location.new(agency: other_agency, name: "Main", code: "MAIN", location_type: "office"), :valid?

    dup = Location.new(agency: @agency, name: "Dup", code: "MAIN", location_type: "branch")
    assert_not dup.valid?
  end

  test "active scope" do
    Location.create!(agency: @agency, name: "Archived", code: "a#{SecureRandom.hex(4)}", location_type: "office", status: "archived")
    keep = Location.create!(agency: @agency, name: "Open", code: "b#{SecureRandom.hex(4)}", location_type: "office")

    active_ids = Location.active.where(agency: @agency).pluck(:id)
    assert_includes active_ids, keep.id
    assert_equal active_ids, active_ids.uniq
    Location.active.where(agency: @agency).each do |l|
      assert_equal "active", l.status
    end
  end
end

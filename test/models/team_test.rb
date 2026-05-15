# frozen_string_literal: true

require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Agency Team", code: "agt#{SecureRandom.hex(4)}")
    @dept = Department.create!(agency: @agency, name: "Dept", code: "D#{SecureRandom.hex(2)}")
    @loc = Location.create!(agency: @agency, name: "HQ", code: "HQ#{SecureRandom.hex(2)}", location_type: "office")
  end

  test "department must match agency when set" do
    other_agency = Agency.create!(name: "O", code: "o#{SecureRandom.hex(4)}")
    foreign_dept = Department.create!(agency: other_agency, name: "FD", code: "fd")

    team = Team.new(
      agency: @agency,
      department: foreign_dept,
      name: "Broken",
      code: "br#{SecureRandom.hex(2)}"
    )
    assert_not team.valid?
    assert team.errors.key?(:department)
  end

  test "location must match agency when set" do
    other_agency = Agency.create!(name: "Z", code: "z#{SecureRandom.hex(4)}")
    foreign_loc = Location.create!(agency: other_agency, name: "L", code: "l#{SecureRandom.hex(2)}", location_type: "office")

    team = Team.new(
      agency: @agency,
      location: foreign_loc,
      name: "Broken Loc",
      code: "bl#{SecureRandom.hex(2)}"
    )
    assert_not team.valid?
    assert team.errors.key?(:location)
  end

  test "department and location both optional valid when matching agency" do
    Team.create!(
      agency: @agency,
      department: nil,
      location: nil,
      name: "Float Team",
      code: "flt#{SecureRandom.hex(3)}"
    )
    Team.create!(
      agency: @agency,
      department: @dept,
      location: @loc,
      name: "Anchored Team",
      code: "anc#{SecureRandom.hex(3)}"
    )

    assert_equal 2, Team.where(agency: @agency).count
  end

  test "team code uniqueness per agency only" do
    Team.create!(agency: @agency, name: "Ops", code: "OPS")
    elsewhere = Agency.create!(name: "Else", code: "e#{SecureRandom.hex(4)}")
    assert_predicate Team.new(agency: elsewhere, name: "Ops Elsewhere", code: "OPS"), :valid?
  end

  test "active scope only returns active statuses" do
    inactive = Team.create!(agency: @agency, name: "Cold", code: "c#{SecureRandom.hex(4)}", status: "inactive")
    live = Team.create!(agency: @agency, name: "Hot", code: "h#{SecureRandom.hex(4)}")

    scoped = Team.active.where(agency: @agency)
    assert_includes scoped.pluck(:id), live.id
    assert_not_includes scoped.pluck(:id), inactive.id
    scoped.each do |t|
      assert_equal "active", t.status
    end
  end
end

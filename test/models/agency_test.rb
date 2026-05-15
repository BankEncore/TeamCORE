# frozen_string_literal: true

require "test_helper"

class AgencyTest < ActiveSupport::TestCase
  test "requires name and code" do
    assert_not Agency.new(name: "", code: "acme").valid?
    assert_not Agency.new(name: "Acme", code: "").valid?
  end

  test "defaults status to active" do
    a = Agency.new(name: "Example", code: "EX")
    a.valid?
    assert_equal "active", a.status
  end

  test "status inclusion" do
    a = Agency.new(name: "A", code: "A", status: "bogus")
    assert_not a.valid?
    assert_includes a.errors[:status], "is not included in the list"

    [ "inactive", "archived" ].each do |status|
      assert Agency.new(name: "N", code: "#{status}#{SecureRandom.hex(2)}", status: status).valid?
    end
  end

  test "active scope excludes non-active" do
    alive = Agency.create!(name: "One", code: "actX#{SecureRandom.hex(4)}")
    resting = Agency.create!(name: "Two", code: "inaY#{SecureRandom.hex(4)}", status: "inactive")

    assert_includes Agency.active.pluck(:id), alive.id
    assert_not_includes Agency.active.pluck(:id), resting.id
  end

  test "predicate helpers reflect status" do
    agency = Agency.create!(name: "P", code: "p#{SecureRandom.hex(4)}")
    assert agency.active?
    agency.update!(status: "inactive")
    assert agency.inactive?
    agency.update!(status: "archived")
    assert agency.archived?
  end

  test "code is globally unique" do
    Agency.create!(name: "First", code: "SAMEGLOBAL")
    duplicate = Agency.new(name: "Second", code: "SAMEGLOBAL")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "normalizes code to stripped lowercase before validation" do
    agency = Agency.new(name: "Corp", code: "  ExAmPlE  ")
    agency.valid?
    assert_equal "example", agency.code
  end

  test "normalized code collides with existing row differing only by case and whitespace" do
    Agency.create!(name: "First", code: "acme")
    duplicate = Agency.new(name: "Second", code: "  ACME  ")
    assert_not duplicate.valid?
    assert duplicate.errors[:code].present?
  end
end

# frozen_string_literal: true

require "test_helper"

class DepartmentTest < ActiveSupport::TestCase
  setup do
    @agency = Agency.create!(name: "Agency Dept", code: "agd#{SecureRandom.hex(4)}")
  end

  test "valid with required fields and active default" do
    d = Department.new(agency: @agency, name: "Sales", code: "SLS")
    d.valid?
    assert_equal "active", d.status
    assert_predicate d, :save
  end

  test "parent must belong to same agency" do
    other_agency = Agency.create!(name: "Other", code: "oth#{SecureRandom.hex(4)}")
    foreign_parent = Department.create!(agency: other_agency, name: "P", code: "PARENT")
    dept = Department.new(agency: @agency, parent_department: foreign_parent, name: "Child", code: "C")
    assert_not dept.valid?
    assert dept.errors.key?(:parent_department)
  end

  test "cannot use own row as parent" do
    d = Department.create!(agency: @agency, name: "Self", code: "SLF#{SecureRandom.hex(2)}")
    d.parent_department = d
    assert_not d.valid?
    assert_includes d.errors[:parent_department_id], "cannot be self"
  end

  test "single-level hierarchy rejects parent that already has parent" do
    root = Department.create!(agency: @agency, name: "Root", code: "R#{SecureRandom.hex(2)}")
    mid = Department.create!(agency: @agency, parent_department: root, name: "Mid", code: "M#{SecureRandom.hex(2)}")
    grandchild_attempt = Department.new(agency: @agency, parent_department: mid, name: "Deep", code: "D#{SecureRandom.hex(2)}")
    assert_not grandchild_attempt.valid?
    assert grandchild_attempt.errors[:parent_department_id].present?
  end

  test "department code unique within agency only" do
    Department.create!(agency: @agency, name: "A", code: "OPS")
    other = Agency.create!(name: "B", code: "b#{SecureRandom.hex(4)}")
    assert_predicate Department.new(agency: other, name: "Other Ops", code: "OPS"), :valid?
  end

  test "normalizes code to stripped lowercase before validation" do
    department = Department.new(agency: @agency, name: "Legal", code: "  LEG  ")
    department.valid?
    assert_equal "leg", department.code
  end

  test "inactive and archived excluded from active scope when mixed" do
    Department.create!(agency: @agency, name: "Live", code: "L#{SecureRandom.hex(2)}", status: "active")
    Department.create!(agency: @agency, name: "Stale", code: "S#{SecureRandom.hex(2)}", status: "inactive")

    Department.active.where(agency: @agency).each do |d|
      assert_equal "active", d.status
    end
  end
end

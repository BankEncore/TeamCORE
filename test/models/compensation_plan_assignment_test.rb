# frozen_string_literal: true

require "test_helper"

class CompensationPlanAssignmentTest < ActiveSupport::TestCase
  setup do
    @agency, = p4_agency_user!
    @ee = p4_active_employee!(@agency)
    @plan = p4_commission_plan!(@agency)
  end

  test "hydrates snapshot from plan on create" do
    asg = CompensationPlanAssignment.create!(
      agency: @agency,
      engagement: @ee[:engagement],
      compensation_plan: @plan,
      effective_start_on: Date.new(2024, 1, 1)
    )

    assert_equal @plan.name, asg.snapshot_plan_name
    assert_equal @plan.plan_type, asg.snapshot_plan_type
    assert_equal @plan.default_commission_rate_bps, asg.snapshot_commission_rate_bps
  end

  test "agency must match engagement" do
    other = Agency.create!(name: "O2", code: "o2#{SecureRandom.hex(4)}")
    asg = CompensationPlanAssignment.new(
      agency: other,
      engagement: @ee[:engagement],
      compensation_plan: @plan,
      effective_start_on: Date.new(2024, 1, 1),
      snapshot_plan_name: "x",
      snapshot_plan_type: "commission_only"
    )

    assert_not asg.valid?
    assert_includes asg.errors[:agency_id].join, "match"
  end
end

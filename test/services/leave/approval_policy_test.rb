# frozen_string_literal: true

require "test_helper"

class Leave::ApprovalPolicyTest < ActiveSupport::TestCase
  setup do
    @agency, @admin = p4_agency_user!
    @eng = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @vacation = @agency.leave_types.find_by!(code: "VACATION")
    @vacation.update!(approval_policy: "manual")
  end

  test "overlap_violation detects submitted neighbor" do
    other = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "submitted")
    LeaveRequestDay.create!(leave_request: other, leave_date: Date.new(2025, 8, 1), hours: 8)

    req = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 8, 1), hours: 4)

    policy = Leave::ApprovalPolicy.new(req)
    assert policy.overlap_violation?
  end

  test "no overlap when neighbor rejected" do
    other = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "rejected")
    LeaveRequestDay.create!(leave_request: other, leave_date: Date.new(2025, 8, 2), hours: 8)

    req = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 8, 2), hours: 8)

    policy = Leave::ApprovalPolicy.new(req)
    assert_not policy.overlap_violation?
  end

  test "excludes self when persisted" do
    req = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 8, 3), hours: 8)

    policy = Leave::ApprovalPolicy.new(req.reload)
    assert_not policy.overlap_violation?
  end
end

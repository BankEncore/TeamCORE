# frozen_string_literal: true

require "test_helper"

class Leave::LeaveRequestServiceTest < ActiveSupport::TestCase
  test "approve consumes balance for paid balance-tracked leave" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 40)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 6, 2), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!
    Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).approve!

    bal = LeaveBalance.find_by!(engagement: eng, leave_type: vacation)
    assert_equal BigDecimal("32"), BigDecimal(bal.balance_hours.to_s)
  end

  test "reject does not change balance-tracked balance" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    sick = agency.leave_types.find_by!(code: "SICK")
    LeaveBalance.create!(engagement: eng, leave_type: sick, balance_hours: 20)

    req = LeaveRequest.create!(engagement: eng, leave_type: sick, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 6, 3), hours: 4)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!
    Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).reject!(review_notes: "no")

    assert_equal BigDecimal("20"), BigDecimal(LeaveBalance.find_by!(engagement: eng, leave_type: sick).balance_hours.to_s)
    assert_equal "rejected", req.reload.status
  end

  test "approve raises when balance insufficient" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 2)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 6, 4), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!

    err =
      assert_raises(Leave::LeaveRequestService::Error) do
        Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).approve!
      end
    assert_match(/Insufficient leave balance/i, err.message)
    assert_equal "submitted", req.reload.status
  end

  test "reopen restores consumed balance" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 40)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 6, 5), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!
    Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).approve!
    Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).reopen_to_draft!(reason: "typo")

    bal = LeaveBalance.find_by!(engagement: eng, leave_type: vacation)
    assert_equal BigDecimal("40"), BigDecimal(bal.balance_hours.to_s)
    assert_equal "draft", req.reload.status
  end
end

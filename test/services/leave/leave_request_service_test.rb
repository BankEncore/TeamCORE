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

  test "manual leave type submit stays submitted until approve" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    vacation.update!(approval_policy: "manual")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 40)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 9, 1), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!

    assert_equal "submitted", req.reload.status
    assert_predicate req.leave_request_approval_events.where(event_type: "submitted"), :exists?
    assert_not_predicate req.leave_request_approval_events.where(event_type: "approved"), :exists?
  end

  test "auto leave type submit approves with system audit event" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    vacation.update!(approval_policy: "auto")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 40)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 9, 2), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!

    req.reload
    assert_equal "approved", req.status
    assert_nil req.reviewed_by_id
    ev = req.leave_request_approval_events.where(event_type: "approved").recent_first.first!
    assert_nil ev.actor_id
    assert_equal "system_policy", ev.metadata_hash["actor_kind"]
    bal = LeaveBalance.find_by!(engagement: eng, leave_type: vacation)
    assert_equal BigDecimal("32"), BigDecimal(bal.balance_hours.to_s)
  end

  test "auto submit raises when balance insufficient" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    vacation.update!(approval_policy: "auto")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 2)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 9, 3), hours: 8)

    assert_raises(Leave::LeaveRequestService::Error) do
      Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!
    end
    assert_equal "draft", req.reload.status
  end

  test "submit blocked when overlapping submitted request exists" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    vacation.update!(approval_policy: "manual")

    blocker = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "submitted")
    LeaveRequestDay.create!(leave_request: blocker, leave_date: Date.new(2025, 9, 10), hours: 8)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 9, 10), hours: 4)

    err = assert_raises(Leave::LeaveRequestService::Error) do
      Leave::LeaveRequestService.new(leave_request: req, actor: admin).submit!
    end
    assert_match(/overlap/i, err.message)
    assert_equal "draft", req.reload.status
  end

  test "approve blocked when overlapping submitted request exists" do
    agency, admin = p4_agency_user!
    eng = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))[:engagement]
    vacation = agency.leave_types.find_by!(code: "VACATION")
    vacation.update!(approval_policy: "manual")
    LeaveBalance.create!(engagement: eng, leave_type: vacation, balance_hours: 80)

    blocker = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "submitted")
    LeaveRequestDay.create!(leave_request: blocker, leave_date: Date.new(2025, 9, 11), hours: 8)

    req = LeaveRequest.create!(engagement: eng, leave_type: vacation, status: "submitted")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 9, 11), hours: 4)

    err = assert_raises(Leave::LeaveRequestService::Error) do
      Leave::LeaveRequestService.new(leave_request: req.reload, actor: admin).approve!
    end
    assert_match(/overlap/i, err.message)
    assert_equal "submitted", req.reload.status
  end
end

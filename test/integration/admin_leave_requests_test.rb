# frozen_string_literal: true

require "test_helper"

class AdminLeaveRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @agency, @user = p4_agency_user!
    @eng = p4_active_employee!(@agency, start_on: Date.new(2025, 1, 1))[:engagement]
    @vacation = @agency.leave_types.find_by!(code: "VACATION")
    LeaveBalance.create!(engagement: @eng, leave_type: @vacation, balance_hours: 40)

    @req = LeaveRequest.create!(engagement: @eng, leave_type: @vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: @req, leave_date: Date.new(2025, 7, 7), hours: 8)

    post login_path, params: { email: @user.email, password: Phase4TestHelper::PASSWORD }
    follow_redirect!
  end

  test "leave queue lists submitted requests" do
    Leave::LeaveRequestService.new(leave_request: @req, actor: @user).submit!

    get admin_leave_requests_path
    assert_response :success
    assert_match(/VACATION/i, response.body)
  end

  test "approve reduces tracked balance" do
    Leave::LeaveRequestService.new(leave_request: @req, actor: @user).submit!

    post approve_admin_leave_request_path(@req.reload)
    assert_redirected_to admin_leave_request_path(@req)

    assert_equal "approved", @req.reload.status
    bal = LeaveBalance.find_by!(engagement: @eng, leave_type: @vacation)
    assert_equal BigDecimal("32"), BigDecimal(bal.balance_hours.to_s)
  end
end

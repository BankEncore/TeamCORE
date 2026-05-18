# frozen_string_literal: true

require "test_helper"

class Team360ProfileAssemblerLeavePanelTest < ActiveSupport::TestCase
  test "leave_panel is nil when focused engagement is not employee path" do
    agency, = p4_agency_user!
    ic = p4_active_ic!(agency)

    snapshot = Team360::ProfileAssembler.new(
      team_member: ic[:team_member],
      agency:,
      focused_engagement_id: ic[:engagement].id
    ).call

    assert_nil snapshot.leave_panel
  end

  test "leave_panel lists balances and recent requests for focused employee" do
    agency, user = p4_agency_user!
    ee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))
    vacation = agency.leave_types.find_by!(code: "VACATION")
    LeaveBalance.create!(engagement: ee[:engagement], leave_type: vacation, balance_hours: 16)

    req = LeaveRequest.create!(engagement: ee[:engagement], leave_type: vacation, status: "draft")
    LeaveRequestDay.create!(leave_request: req, leave_date: Date.new(2025, 4, 1), hours: 8)

    Leave::LeaveRequestService.new(leave_request: req, actor: user).submit!

    snapshot = Team360::ProfileAssembler.new(
      team_member: ee[:team_member],
      agency:,
      current_user: user,
      focused_engagement_id: ee[:engagement].id
    ).call

    panel = snapshot.leave_panel
    assert panel
    vac_bal = panel[:balances].find { |b| b[:leave_type_code] == "VACATION" }
    assert_equal "16.0", vac_bal[:balance_hours]

    row = panel[:requests].find { |r| r[:id] == req.id }
    assert_equal "manual", row[:approval_policy]
    assert_equal false, row[:auto_approved]
    assert_equal "Projected leave", row[:visibility_label]
    assert_equal "submitted", row[:status]
  end
end

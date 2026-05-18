# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :user_agencies, dependent: :destroy
  has_many :agencies, through: :user_agencies
  has_many :verified_document_records, class_name: "DocumentRecord", foreign_key: :verified_by_id, inverse_of: :verified_by,
    dependent: :restrict_with_exception
  has_many :draw_balance_events, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_many :contractor_charge_waivers, foreign_key: :actor_id, inverse_of: :actor, dependent: :restrict_with_exception
  has_many :contractor_charge_recoveries, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_many :closed_pay_periods, class_name: "PayPeriod", foreign_key: :closed_by_id, inverse_of: :closed_by,
    dependent: :restrict_with_exception
  has_many :exported_payroll_exports, class_name: "PayrollExport", foreign_key: :exported_by_id,
    inverse_of: :exported_by, dependent: :nullify
  has_many :exported_contractor_settlement_exports, class_name: "ContractorSettlementExport", foreign_key: :exported_by_id,
    inverse_of: :exported_by, dependent: :nullify
  has_many :weekly_timesheets_approved, class_name: "WeeklyTimesheet", foreign_key: :approved_by_id,
    inverse_of: :approved_by, dependent: :nullify
  has_many :weekly_timesheet_approval_events_as_actor,
    class_name: "WeeklyTimesheetApprovalEvent",
    foreign_key: :actor_id,
    inverse_of: :actor,
    dependent: :restrict_with_exception
  has_many :reviewed_leave_requests, class_name: "LeaveRequest", foreign_key: :reviewed_by_id,
    inverse_of: :reviewed_by, dependent: :nullify
  has_many :leave_request_approval_events_as_actor,
    class_name: "LeaveRequestApprovalEvent",
    foreign_key: :actor_id,
    inverse_of: :actor,
    dependent: :restrict_with_exception
  has_many :leave_balance_adjustments_as_actor,
    class_name: "LeaveBalanceAdjustment",
    foreign_key: :adjusted_by_id,
    inverse_of: :adjusted_by,
    dependent: :restrict_with_exception

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Team360 §12.2 — employee draw visibility; permissive default until TC-29/30 role model.
  def team360_show_employee_draw_balance?
    true
  end
end

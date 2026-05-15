# frozen_string_literal: true

# TC-04 policy hints for downstream epics — not OD-006 readiness, OD-009 permission gates,
# or payroll/settlement/time/leave engines. See docs/domain/engagement-status.md.
module EngagementWorkflowEligibility
  extend ActiveSupport::Concern

  CONTRACTOR_CLASS_RELATIONSHIP_TYPES = %w[
    individual_contractor
    contractor_organization
    subcontractor
  ].freeze

  def employee_relationship?
    relationship_type == "employee"
  end

  # Alias for acceptance naming (`employee_path?`).
  def employee_path?
    employee_relationship?
  end

  def contractor_class_relationship?
    CONTRACTOR_CLASS_RELATIONSHIP_TYPES.include?(relationship_type)
  end

  # Alias for acceptance naming (`contractor_class?`).
  def contractor_class?
    contractor_class_relationship?
  end

  def individual_contractor_path?
    relationship_type == "individual_contractor"
  end

  def contractor_organization_path?
    relationship_type == "contractor_organization"
  end

  def subcontractor_path?
    relationship_type == "subcontractor"
  end

  # Workforce engagement terminals (same as Engagement::TERMINAL_STATUSES).
  def terminal?
    self.class::TERMINAL_STATUSES.include?(status)
  end

  def suspended?
    status == "suspended"
  end

  # Time, leave, payroll **input** rails (employee-only, MVP framing).
  def eligible_for_employee_operational_rails?
    employee_relationship? && status == "active"
  end

  # Per-rail aliases — same MVP hinge as +eligible_for_employee_operational_rails?+ (TC-04 matrix).
  def active_for_time_tracking?
    eligible_for_employee_operational_rails?
  end

  def active_for_leave?
    eligible_for_employee_operational_rails?
  end

  def active_for_payroll_input?
    eligible_for_employee_operational_rails?
  end

  # Settlement eligibility hint — same hinge as broader contractor-class operational rails.
  def active_for_contractor_settlement?
    eligible_for_contractor_class_operational_rails?
  end

  # Settlement / contractor charges–class rails (when implemented).
  def eligible_for_contractor_class_operational_rails?
    contractor_class_relationship? && status == "active"
  end

  # TC-04-D03: non-+active+ statuses block new forward operational work at this layer.
  def operational_forward_work_blocked_by_status?
    status != "active"
  end
end

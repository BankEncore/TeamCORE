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

  def contractor_class_relationship?
    CONTRACTOR_CLASS_RELATIONSHIP_TYPES.include?(relationship_type)
  end

  # Time, leave, payroll **input** rails (employee-only, MVP framing).
  def eligible_for_employee_operational_rails?
    employee_relationship? && status == "active"
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

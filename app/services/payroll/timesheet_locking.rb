# frozen_string_literal: true

module Payroll
  # ADR-0003 MVP locking matrix for editing daily worked-hour rows (caller supplies actor role).
  module TimesheetLocking
    module_function

    # @param role [Symbol] :employee, :direct_supervisor, :payroll_admin
    # @param supervisor_engagement [Engagement, nil] required when role is :direct_supervisor (validated upstream)
    def daily_hours_editable?(timesheet:, role:, supervisor_engagement: nil)
      case timesheet.status
      when "draft"
        case role
        when :employee, :direct_supervisor, :payroll_admin then true
        else false
        end
      when "submitted"
        case role
        when :employee then false
        when :direct_supervisor, :payroll_admin then true
        else false
        end
      when "approved"
        case role
        when :employee, :direct_supervisor then false
        when :payroll_admin then true
        else false
        end
      when "rejected"
        case role
        when :employee, :direct_supervisor, :payroll_admin then true
        else false
        end
      else
        false
      end
    end

    def can_submit?(timesheet:, role:)
      return false unless timesheet.status == "draft"

      case role
      when :employee, :direct_supervisor, :payroll_admin then true
      else false
      end
    end
  end
end

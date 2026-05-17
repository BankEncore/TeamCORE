# frozen_string_literal: true

module Payroll
  module TimesheetLocking
    module_function

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

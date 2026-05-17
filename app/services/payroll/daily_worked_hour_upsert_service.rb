# frozen_string_literal: true

module Payroll
  class DailyWorkedHourUpsertService
    class Error < StandardError; end

    # @param role [Symbol] :employee, :direct_supervisor, :payroll_admin
    # @param actor_engagement [Engagement, nil] employee's engagement when role is :employee; supervisor's engagement when :direct_supervisor
    # @param supervisor_engagement [Engagement, nil] optional explicit supervisor engagement for :direct_supervisor
    def self.call(engagement:, work_date:, hours:, notes: nil, source:, role:, actor_engagement: nil,
                  supervisor_engagement: nil)
      verify_actor!(engagement:, work_date:, role:, actor_engagement:, supervisor_engagement:)

      sheet = TimesheetAssemblyService.ensure!(engagement, reference_date: work_date)
      sup_for_lock = role == :direct_supervisor ? supervisor_engagement.presence || actor_engagement : nil
      unless TimesheetLocking.daily_hours_editable?(timesheet: sheet, role:, supervisor_engagement: sup_for_lock)
        raise Error, "Daily hours are not editable for this timesheet state and actor"
      end

      row = DailyWorkedHour.find_or_initialize_by(engagement_id: engagement.id, work_date:)
      row.hours = hours
      row.notes = notes if notes.present?
      row.source = source
      row.save!
      row
    end

    def self.verify_actor!(engagement:, work_date:, role:, actor_engagement:, supervisor_engagement:)
      case role
      when :employee
        if actor_engagement.blank? || actor_engagement.id != engagement.id
          raise Error, "Employee edits must use the same engagement as the timesheet owner"
        end
      when :direct_supervisor
        sup = supervisor_engagement.presence || actor_engagement
        if sup.blank? || !Supervision.primary_supervises?(supervisor_engagement: sup, supervised_engagement: engagement,
                                                           as_of: work_date)
          raise Error, "Supervisor is not the primary supervisor for this engagement on this date"
        end
      when :payroll_admin
        # trusted caller (authorization at controller/service boundary)
      else
        raise Error, "Unsupported actor role"
      end
    end
    private_class_method :verify_actor!
  end
end

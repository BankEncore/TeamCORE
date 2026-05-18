# frozen_string_literal: true

module Payroll
  class TimesheetSubmissionService
    SubmissionResult = Data.define(:timesheet, :warnings)

    class Error < StandardError; end

    # @param role [Symbol] :employee, :direct_supervisor, :payroll_admin
    def self.call(timesheet:, role:, actor_engagement: nil)
      raise Error, "Timesheet must be draft to submit" unless timesheet.status == "draft"

      verify_submitter!(timesheet:, role:, actor_engagement:)
      unless TimesheetLocking.can_submit?(timesheet:, role:)
        raise Error, "This actor cannot submit this timesheet"
      end

      if negative_hours?(timesheet)
        raise Error, "Cannot submit while any day has negative hours"
      end

      warnings = missing_weekday_warnings(timesheet)

      timesheet.transaction do
        timesheet.update!(status: "submitted", submitted_at: Time.current)
      end

      SubmissionResult.new(timesheet: timesheet.reload, warnings:)
    end

    def self.verify_submitter!(timesheet:, role:, actor_engagement:)
      case role
      when :employee
        if actor_engagement.blank? || actor_engagement.id != timesheet.engagement_id
          raise Error, "Employee submission must be from the timesheet owner engagement"
        end
      when :direct_supervisor
        if actor_engagement.blank? ||
            !Supervision.primary_supervises?(
              supervisor_engagement: actor_engagement,
              supervised_engagement: timesheet.engagement,
              as_of: timesheet.week_end_on
            )
          raise Error, "Supervisor cannot submit this timesheet"
        end
      when :payroll_admin
        nil
      else
        raise Error, "Unsupported actor role"
      end
    end
    private_class_method :verify_submitter!

    def self.negative_hours?(timesheet)
      DailyWorkedHour.where(engagement_id: timesheet.engagement_id, work_date: timesheet.week_start_on..timesheet.week_end_on)
        .where("hours < 0").exists?
    end
    private_class_method :negative_hours?

    # Warn-only (ADR-0003): do not block submit for sparse weeks (part-time, leave, holidays).
    def self.missing_weekday_warnings(timesheet)
      warnings = []
      (timesheet.week_start_on..timesheet.week_end_on).each do |d|
        next if d.saturday? || d.sunday?

        exists = DailyWorkedHour.exists?(engagement_id: timesheet.engagement_id, work_date: d)
        warnings << "No hours entered for #{d}" unless exists
      end
      warnings
    end
    private_class_method :missing_weekday_warnings
  end
end

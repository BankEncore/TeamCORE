# frozen_string_literal: true

module Payroll
  class TimesheetAssemblyService
    class Error < StandardError; end

    # Ensures a weekly timesheet row exists for the workweek containing reference_date.
    # @return [WeeklyTimesheet]
    def self.ensure!(engagement, reference_date:)
      week_start, week_end = TimesheetWeekResolver.week_range_for(engagement, reference_date)

      WeeklyTimesheet.transaction(requires_new: true) do
        sheet = WeeklyTimesheet.lock.find_or_initialize_by(engagement_id: engagement.id, week_start_on: week_start)
        if sheet.new_record?
          sheet.week_end_on = week_end
          sheet.status = "draft"
        elsif sheet.week_end_on != week_end
          raise Error, "Stored week_end_on does not match payroll calendar for this week_start_on"
        end
        sheet.save!
        sheet
      end
    end
  end
end

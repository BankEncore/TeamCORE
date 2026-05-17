# frozen_string_literal: true

module Payroll
  module WorkweekWorkedHoursAggregator
    module_function

    def daily_hours_hash(engagement:, week_start_on:, week_end_on:)
      DailyWorkedHour.where(engagement_id: engagement.id, work_date: week_start_on..week_end_on)
        .pluck(:work_date, :hours)
        .to_h { |date, hrs| [ date, hrs ] }
    end

    def for_timesheet(timesheet)
      daily_hours_hash(
        engagement: timesheet.engagement,
        week_start_on: timesheet.week_start_on,
        week_end_on: timesheet.week_end_on
      )
    end
  end
end

# frozen_string_literal: true

module Payroll
  module TimesheetWeekResolver
    module_function

    # @return [Array(Date, Date)] week_start_on, week_end_on inclusive
    def week_range_for(engagement, date)
      config = engagement.agency.agency_payroll_configuration
      WorkweekBoundary.range_for(date, workweek_starts_on: config.workweek_starts_on)
    end
  end
end

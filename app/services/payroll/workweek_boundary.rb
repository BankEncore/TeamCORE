# frozen_string_literal: true

module Payroll
  # Civil dates for MVP: workweek bounds use the configured weekday in the agency payroll timezone's
  # calendar (see ADR-0002). Overnight punch resolution defers to later time-tracking work.
  module WorkweekBoundary
    module_function

    # @param date [Date]
    # @param workweek_starts_on [Integer] Ruby Date.wday (0 = Sunday … 6 = Saturday)
    # @return [Array<Date, Date>] week_start, week_end inclusive
    def range_for(date, workweek_starts_on:)
      sym = wday_to_beginning_of_week_symbol(workweek_starts_on)
      start_date = date.beginning_of_week(sym)
      [ start_date, start_date + 6.days ]
    end

    def wday_to_beginning_of_week_symbol(workweek_starts_on)
      name = Date::DAYNAMES.fetch(workweek_starts_on)
      :"#{name.downcase}"
    end
  end
end

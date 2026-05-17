# frozen_string_literal: true

module Payroll
  # Enumerates civil workweek ranges (Mon–Sun style bounds per ADR-0002) that intersect a pay period.
  module PayPeriodWorkweeks
    module_function

    # @yieldparam week_start [Date]
    # @yieldparam week_end [Date]
    def each_intersecting(pay_period, workweek_starts_on:)
      return enum_for(:each_intersecting, pay_period, workweek_starts_on:) unless block_given?

      d = pay_period.start_on
      seen_starts = {}
      while d <= pay_period.end_on
        week_start, week_end = WorkweekBoundary.range_for(d, workweek_starts_on:)
        unless seen_starts[week_start]
          seen_starts[week_start] = true
          if week_end >= pay_period.start_on && week_start <= pay_period.end_on
            yield week_start, week_end
          end
        end
        d = week_end + 1.day
      end
    end
  end
end

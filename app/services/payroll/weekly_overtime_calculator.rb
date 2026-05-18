# frozen_string_literal: true

module Payroll
  # Computes weekly overtime from daily worked hours (leave excluded by caller — worked hours only).
  class WeeklyOvertimeCalculator
    Result = Data.define(:regular_hours, :overtime_hours)

    # @param workweek_start [Date]
    # @param workweek_end [Date]
    # @param daily_worked_hours [Hash{Date => Numeric}] may include keys outside the week; they are ignored
    # @param threshold_hours [Numeric]
    def self.compute(workweek_start:, workweek_end:, daily_worked_hours:, threshold_hours:)
      total = BigDecimal("0")
      (workweek_start..workweek_end).each do |d|
        next unless daily_worked_hours.key?(d)

        total += BigDecimal(daily_worked_hours[d].to_s)
      end

      threshold = BigDecimal(threshold_hours.to_s)
      if total > threshold
        Result.new(regular_hours: threshold, overtime_hours: total - threshold)
      else
        Result.new(regular_hours: total, overtime_hours: BigDecimal("0"))
      end
    end
  end
end

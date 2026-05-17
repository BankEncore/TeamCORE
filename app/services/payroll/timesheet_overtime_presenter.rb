# frozen_string_literal: true

module Payroll
  # REG/OT visibility from daily rows + timesheet status (ADR-0003 projected vs approved).
  TimesheetOvertimeView = Data.define(:regular_hours, :overtime_hours, :visibility_mode)

  module TimesheetOvertimePresenter
    module_function

    # @return [TimesheetOvertimeView] visibility_mode is :projected or :approved
    def for_timesheet(timesheet)
      config = timesheet.engagement.agency.agency_payroll_configuration
      daily = WorkweekWorkedHoursAggregator.for_timesheet(timesheet)
      calc = WeeklyOvertimeCalculator.compute(
        workweek_start: timesheet.week_start_on,
        workweek_end: timesheet.week_end_on,
        daily_worked_hours: daily,
        threshold_hours: config.weekly_overtime_threshold_hours
      )

      mode = timesheet.status == "approved" ? :approved : :projected

      TimesheetOvertimeView.new(
        regular_hours: calc.regular_hours,
        overtime_hours: calc.overtime_hours,
        visibility_mode: mode
      )
    end
  end
end

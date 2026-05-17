# frozen_string_literal: true

module Payroll
  # Sums approved worked REG/OT for pay-period preparation (TC-23 slice — no leave or export payloads).
  class PayrollSummaryAggregator
    def initialize(agency:, pay_period:, engagement: nil, **_sources)
      @agency = agency
      @pay_period = pay_period
      @engagement = engagement
    end

    def call
      regular = BigDecimal("0")
      overtime = BigDecimal("0")

      engagements_scope.each do |eng|
        WeeklyTimesheet.approved.where(engagement_id: eng.id)
          .where(week_end_on: pay_period.start_on..pay_period.end_on).find_each do |sheet|
            ot_view = TimesheetOvertimePresenter.for_timesheet(sheet)
            next unless ot_view.visibility_mode == :approved

            regular += ot_view.regular_hours
            overtime += ot_view.overtime_hours
          end
      end

      total_worked = regular + overtime
      hours_by_earning_code = earning_code_breakdown(regular, overtime)

      PayrollSummary.new(
        regular_hours: regular,
        overtime_hours: overtime,
        leave_hours: BigDecimal("0"),
        total_paid_hours: total_worked,
        hours_by_earning_code: hours_by_earning_code
      )
    end

    private

    attr_reader :agency, :pay_period, :engagement

    def engagements_scope
      if engagement.present?
        [ engagement ]
      else
        Engagement.where(agency_id: agency.id, relationship_type: "employee", status: "active")
          .where("start_on <= ?", pay_period.end_on)
      end
    end

    def earning_code_breakdown(regular, overtime)
      return {} if regular.zero? && overtime.zero?

      {
        PayrollEarningCode.regular_worked.code => regular,
        PayrollEarningCode.overtime_worked.code => overtime
      }
    end
  end
end

# frozen_string_literal: true

module Payroll
  # Sums approved worked REG/OT and approved leave day rows overlapping the pay period (visibility hooks).
  class PayrollSummaryAggregator
    def initialize(agency:, pay_period:, engagement: nil, **_sources)
      @agency = agency
      @pay_period = pay_period
      @engagement = engagement
    end

    def call
      regular = BigDecimal("0")
      overtime = BigDecimal("0")
      paid_leave = BigDecimal("0")
      unpaid_leave = BigDecimal("0")

      engagements_scope.each do |eng|
        WeeklyTimesheet.approved.where(engagement_id: eng.id)
          .where(week_end_on: pay_period.start_on..pay_period.end_on).find_each do |sheet|
            ot_view = TimesheetOvertimePresenter.for_timesheet(sheet)
            next unless ot_view.visibility_mode == :approved

            regular += ot_view.regular_hours
            overtime += ot_view.overtime_hours
          end

        LeaveRequest.where(engagement_id: eng.id, status: "approved").includes(:leave_type, :leave_request_days).find_each do |req|
          req.leave_request_days.each do |day|
            next unless (pay_period.start_on..pay_period.end_on).cover?(day.leave_date)

            h = BigDecimal(day.hours.to_s)
            if req.leave_type.paid?
              paid_leave += h
            else
              unpaid_leave += h
            end
          end
        end
      end

      total_worked = regular + overtime
      hours_by_earning_code = earning_code_breakdown(regular, overtime, paid_leave, engagements_scope)

      PayrollSummary.new(
        regular_hours: regular,
        overtime_hours: overtime,
        paid_leave_hours: paid_leave,
        unpaid_leave_hours: unpaid_leave,
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

    # Builds REG/OT from worked hours; adds paid leave hours into global earning codes by leave type mapping.
    def earning_code_breakdown(regular, overtime, paid_leave, engs)
      out = {}
      out[PayrollEarningCode.regular_worked.code] = regular if regular.positive?
      out[PayrollEarningCode.overtime_worked.code] = overtime if overtime.positive?

      eng_ids = engs.map(&:id)
      return out if paid_leave.zero? || eng_ids.empty?

      LeaveRequest.where(engagement_id: eng_ids, status: "approved").includes(:leave_type, :leave_request_days).find_each do |req|
        pec = req.leave_type.payroll_earning_code
        next if pec.blank?

        req.leave_request_days.each do |day|
          next unless (pay_period.start_on..pay_period.end_on).cover?(day.leave_date)
          next unless req.leave_type.paid?

          h = BigDecimal(day.hours.to_s)
          code = pec.code
          out[code] = (out[code] || BigDecimal("0")) + h
        end
      end

      out
    end
  end
end

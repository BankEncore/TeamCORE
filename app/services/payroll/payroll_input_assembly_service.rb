# frozen_string_literal: true

module Payroll
  class PayrollInputAssemblyService
    class Error < StandardError; end

    def self.call(batch:, actor: nil)
      new(batch:, actor:).call
    end

    def initialize(batch:, actor:)
      @batch = batch
      @actor = actor
    end

    def call
      raise Error, "Only draft batches can be assembled." unless batch.draft?

      batch.transaction do
        batch.payroll_input_rows.delete_all
        build_timesheet_rows!
        build_leave_rows!
        build_commission_draw_rows!
        build_adjustment_rows!
      end

      batch.reload
    end

    private

    attr_reader :batch, :actor

    def agency
      batch.agency
    end

    def pay_period
      batch.pay_period
    end

    def period_range
      pay_period.start_on..pay_period.end_on
    end

    def engagements_scope
      Engagement.where(agency_id: agency.id, relationship_type: "employee", status: "active")
        .where("start_on <= ?", pay_period.end_on)
    end

    def build_timesheet_rows!
      engagements_scope.find_each do |eng|
        WeeklyTimesheet.approved.where(engagement_id: eng.id)
          .where(week_end_on: period_range).find_each do |sheet|
          ot = TimesheetOvertimePresenter.for_timesheet(sheet)
          next unless ot.visibility_mode == :approved

          add_row(eng, PayrollEarningCode.regular_worked.code, "earning", ot.regular_hours, nil, sheet, {}) if ot.regular_hours.positive?
          add_row(eng, PayrollEarningCode.overtime_worked.code, "earning", ot.overtime_hours, nil, sheet, {}) if ot.overtime_hours.positive?
        end
      end
    end

    def build_leave_rows!
      engagements_scope.find_each do |eng|
        LeaveRequest.where(engagement_id: eng.id, status: "approved").includes(:leave_type, :leave_request_days).find_each do |req|
          pec = req.leave_type.payroll_earning_code
          next if pec.blank?

          req.leave_request_days.each do |day|
            next unless period_range.cover?(day.leave_date)
            next unless req.leave_type.paid?

            hours = BigDecimal(day.hours.to_s)
            next unless hours.positive?

            add_row(eng, pec.code, "earning", hours, nil, day, {})
          end
        end
      end
    end

    def build_commission_draw_rows!
      ids = engagements_scope.pluck(:id)
      Payroll::CommissionDrawAssembly.line_candidates(agency:, pay_period:, engagement_ids: ids).each do |line|
        eng = Engagement.find_by(id: line.engagement_id, agency_id: agency.id)
        next unless eng

        direction = line.direction.presence || "earning"
        add_row(
          eng,
          line.earning_code,
          direction,
          line.hours,
          line.amount,
          nil,
          line.metadata || {},
          currency: line.currency.presence || "USD"
        )
      end
    end

    def build_adjustment_rows!
      batch.payroll_input_adjustments.includes(:payroll_adjustment_code).find_each do |adj|
        code = adj.payroll_adjustment_code
        add_row(
          adj.engagement,
          code.code,
          code.direction,
          adj.hours,
          adj.amount,
          adj,
          { "notes" => adj.notes }.compact,
          currency: adj.currency
        )
      end
    end

    def add_row(engagement, earning_code, direction, hours, amount, source, metadata = {}, currency: "USD")
      attrs = {
        payroll_input_batch_id: batch.id,
        engagement_id: engagement.id,
        earning_code: earning_code,
        direction: direction,
        hours: hours,
        amount: amount,
        currency: currency,
        metadata: metadata.presence
      }.compact
      attrs[:source] = source if source.present?

      PayrollInputRow.create!(attrs)
    end
  end
end

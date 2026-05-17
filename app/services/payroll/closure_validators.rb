# frozen_string_literal: true

module Payroll
  module ClosureValidators
    class Result
      attr_reader :violations

      def initialize(violations = [])
        @violations = violations
      end

      def blocking?
        violations.any?
      end

      def message
        violations.join(" ")
      end
    end

    # MVP (ADR-0003): missing means no WeeklyTimesheet row for each workweek intersecting the period.
    class MissingTimesheets
      def self.call(agency:, pay_period:)
        violations = []
        config = agency.agency_payroll_configuration

        Engagement.where(agency_id: agency.id, relationship_type: "employee", status: "active")
          .where("start_on <= ?", pay_period.end_on)
          .find_each do |eng|
          Payroll::PayPeriodWorkweeks.each_intersecting(pay_period, workweek_starts_on: config.workweek_starts_on) do |week_start, _week_end|
            exists = WeeklyTimesheet.exists?(engagement_id: eng.id, week_start_on: week_start)
            next if exists

            violations <<
              "Missing weekly timesheet for engagement #{eng.id} (#{week_start.iso8601})"
          end
        end

        Result.new(violations)
      end
    end

    class PendingApprovals
      def self.call(agency:, pay_period:)
        pending = WeeklyTimesheet.joins(:engagement)
          .where(engagements: { agency_id: agency.id })
          .where(status: "submitted")
          .merge(WeeklyTimesheet.for_pay_period_overlap(pay_period))
          .count

        violations = []
        violations << "#{pending} weekly timesheet(s) awaiting approval" if pending.positive?

        Result.new(violations)
      end
    end
  end
end

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

    # Placeholder until employee timesheets exist.
    class MissingTimesheets
      def self.call(agency:, pay_period:)
        Result.new([])
      end
    end

    # Placeholder until approval workflows exist.
    class PendingApprovals
      def self.call(agency:, pay_period:)
        Result.new([])
      end
    end
  end
end

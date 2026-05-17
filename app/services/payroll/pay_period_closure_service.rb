# frozen_string_literal: true

module Payroll
  class PayPeriodClosureService
    VALIDATORS = [
      ClosureValidators::MissingTimesheets,
      ClosureValidators::PendingApprovals
    ].freeze

    class Error < StandardError; end

    # @param override_validation [Boolean] skips MissingTimesheets/PendingApprovals checks only (ADR posture).
    def self.call(pay_period:, actor:, override_validation: false, validators: VALIDATORS)
      new(pay_period:, actor:, override_validation:, validators:).call
    end

    def initialize(pay_period:, actor:, override_validation:, validators:)
      @pay_period = pay_period
      @actor = actor
      @override_validation = override_validation
      @validators = validators
    end

    def call
      raise Error, "Pay period is already closed." if pay_period.closed?
      unless Access.can_close_pay_period?(user: actor, agency: pay_period.agency)
        raise Error, "Not permitted to close pay periods for this agency."
      end

      unless override_validation
        validators.each do |validator|
          result = validator.call(agency: pay_period.agency, pay_period:)
          raise Error, result.message if result.blocking?
        end
      end

      pay_period.transaction do
        pay_period.update!(
          status: "closed",
          closed_at: Time.current,
          closed_by: actor
        )
      end

      pay_period
    end

    private

    attr_reader :pay_period, :actor, :override_validation, :validators
  end
end

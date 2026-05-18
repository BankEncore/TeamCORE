# frozen_string_literal: true

module Payroll
  class PayPeriodClosureService
    VALIDATORS = [
      ClosureValidators::MissingTimesheets,
      ClosureValidators::PendingApprovals
    ].freeze

    class Error < StandardError; end

    # @param override_validation [Boolean] skips MissingTimesheets/PendingApprovals checks only (ADR posture).
    # @param source [String] PayPeriodClosureEvent source (e.g. admin_manual, payroll_final_export).
    # @param override_reason [String] required when override_validation is true.
    # @param payroll_input_batch_id [Integer] optional linkage when TC-27 triggers closure.
    def self.call(pay_period:, actor:, override_validation: false, validators: VALIDATORS,
                  source: PayPeriodClosureEvent::SOURCES.fetch(:admin_manual),
                  override_reason: nil,
                  payroll_input_batch_id: nil,
                  metadata: {})
      new(
        pay_period:,
        actor:,
        override_validation:,
        validators:,
        source:,
        override_reason:,
        payroll_input_batch_id:,
        metadata:
      ).call
    end

    def initialize(pay_period:, actor:, override_validation:, validators:, source:, override_reason:,
                   payroll_input_batch_id:, metadata:)
      @pay_period = pay_period
      @actor = actor
      @override_validation = override_validation
      @validators = validators
      @source = source
      @override_reason = override_reason
      @payroll_input_batch_id = payroll_input_batch_id
      @metadata = metadata
    end

    def call
      raise Error, "Pay period is already closed." if pay_period.closed?
      unless Access.can_close_pay_period?(user: actor, agency: pay_period.agency)
        raise Error, "Not permitted to close pay periods for this agency."
      end

      if override_validation && override_reason.to_s.strip.blank?
        raise Error, "Override reason is required when overriding closure validation."
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

        PayPeriodClosureEvent.create!(
          pay_period: pay_period,
          payroll_input_batch_id: payroll_input_batch_id,
          event_type: override_validation ? "override_closed" : "closed",
          actor: actor,
          occurred_at: Time.current,
          source: source,
          override_validation: override_validation,
          override_reason: override_validation ? override_reason.to_s.strip : nil,
          metadata: metadata.presence || {}
        )
      end

      pay_period
    end

    private

    attr_reader :pay_period, :actor, :override_validation, :validators, :source, :override_reason,
                :payroll_input_batch_id, :metadata
  end
end

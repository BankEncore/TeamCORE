# frozen_string_literal: true

module Payroll
  class FinalizePayrollInputBatchService
    class Error < StandardError; end

    def self.call(batch:, actor:)
      new(batch:, actor:).call
    end

    def initialize(batch:, actor:)
      @batch = batch
      @actor = actor
    end

    def call
      raise Error, "Only draft batches can be finalized." unless batch.draft?
      raise Error, "Pay period is closed." if batch.pay_period.closed?

      validators.each do |validator|
        result = validator.call(agency: batch.agency, pay_period: batch.pay_period)
        raise Error, result.message if result.blocking?
      end

      batch.transaction do
        batch.update!(
          status: "finalized",
          finalized_at: Time.current,
          finalized_by_id: actor.id
        )
      end

      batch.reload
    end

    private

    attr_reader :batch, :actor

    def validators
      Payroll::PayPeriodClosureService::VALIDATORS
    end
  end
end

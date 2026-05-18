# frozen_string_literal: true

module Payroll
  class PayrollInputBatchEnsureDraftService
    class Error < StandardError; end

    def self.call(pay_period:, actor: nil)
      new(pay_period:, actor:).call
    end

    def initialize(pay_period:, actor:)
      @pay_period = pay_period
      @actor = actor
    end

    def call
      existing = PayrollInputBatch.drafts.find_by(agency_id: pay_period.agency_id, pay_period_id: pay_period.id)
      return existing if existing

      batch = nil
      PayPeriod.transaction do
        pay_period.lock!
        raise Error, "Pay period is closed." if pay_period.closed?

        batch = PayrollInputBatch.drafts.where(agency_id: pay_period.agency_id, pay_period_id: pay_period.id).first
        batch ||= PayrollInputBatch.create!(agency_id: pay_period.agency_id, pay_period_id: pay_period.id, status: "draft")
      end

      PayrollInputAssemblyService.call(batch:, actor: actor)
      batch.reload
    end

    private

    attr_reader :pay_period, :actor
  end
end

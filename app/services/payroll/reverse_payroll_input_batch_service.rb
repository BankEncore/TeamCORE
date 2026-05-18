# frozen_string_literal: true

module Payroll
  class ReversePayrollInputBatchService
    class Error < StandardError; end

    def self.call(batch:, actor:, reason:)
      new(batch:, actor:, reason:).call
    end

    def initialize(batch:, actor:, reason:)
      @batch = batch
      @actor = actor
      @reason = reason
    end

    def call
      raise Error, "Only finalized batches can be reversed." unless batch.finalized?
      raise Error, "Exported batches cannot be reversed." if batch.payroll_export_id.present?
      raise Error, "Reason is required." if reason.to_s.strip.blank?

      successor = nil
      PayrollInputBatch.transaction do
        batch.reload
        raise Error, "Batch changed; reload and try again." unless batch.finalized?

        successor = PayrollInputBatch.create!(
          agency_id: batch.agency_id,
          pay_period_id: batch.pay_period_id,
          status: "draft",
          supersedes_batch_id: batch.id
        )

        batch.update!(
          status: "reversed",
          reversed_at: Time.current,
          reversed_by_id: actor.id,
          reversal_reason: reason.to_s.strip,
          superseded_by_batch_id: successor.id
        )
      end

      PayrollInputAssemblyService.call(batch: successor, actor: actor)
      successor.reload
    end

    private

    attr_reader :batch, :actor, :reason
  end
end

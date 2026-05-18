# frozen_string_literal: true

module Payroll
  class MarkPayrollInputBatchExportedService
    class Error < StandardError; end

    def self.call(batch:, actor:, file_format: "csv", override_validation: false, override_reason: nil)
      new(batch:, actor:, file_format:, override_validation:, override_reason:).call
    end

    def initialize(batch:, actor:, file_format:, override_validation:, override_reason:)
      @batch = batch
      @actor = actor
      @file_format = file_format
      @override_validation = override_validation
      @override_reason = override_reason
    end

    def call
      raise Error, "Only finalized batches can be exported." unless batch.finalized?
      raise Error, "Pay period is already closed." if batch.pay_period.closed?
      if override_validation && override_reason.to_s.strip.blank?
        raise Error, "Override reason is required when overriding closure validation."
      end

      PayrollInputBatch.transaction do
        batch.reload
        raise Error, "Batch is no longer finalized." unless batch.finalized?

        export = PayrollExport.create!(
          pay_period: batch.pay_period,
          exported_by: actor,
          is_final: true,
          file_format: file_format,
          exported_at: Time.current
        )

        batch.update!(
          status: "exported",
          payroll_export: export,
          exported_at: Time.current,
          exported_by_id: actor.id
        )

        Payroll::PayPeriodClosureService.call(
          pay_period: batch.pay_period,
          actor: actor,
          override_validation: override_validation,
          override_reason: override_reason,
          source: PayPeriodClosureEvent::SOURCES.fetch(:payroll_final_export),
          payroll_input_batch_id: batch.id
        )
      end

      batch.reload
    rescue Payroll::PayPeriodClosureService::Error => e
      raise Error, e.message
    end

    private

    attr_reader :batch, :actor, :file_format, :override_validation, :override_reason
  end
end

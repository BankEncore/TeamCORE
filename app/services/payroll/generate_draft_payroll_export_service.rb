# frozen_string_literal: true

require "digest"
require "stringio"

module Payroll
  class GenerateDraftPayrollExportService
    class Error < StandardError; end

    def self.call(batch:, actor:, file_format: "csv")
      new(batch:, actor:, file_format:).call
    end

    def initialize(batch:, actor:, file_format:)
      @batch = batch
      @actor = actor
      @file_format = file_format.to_s.downcase
    end

    def call
      raise Error, "Only finalized batches can be exported." unless batch.finalized?
      raise Error, "Pay period must be open for draft exports." unless batch.pay_period.open?
      unless PayrollExport::FILE_FORMATS.include?(file_format)
        raise Error, "Unsupported file format."
      end

      binary, content_type, filename =
        PayrollExportFileBuilder.call(batch:, format: file_format, draft: true)
      snapshot = PayrollExportValidationSnapshot.call(
        agency: batch.agency,
        pay_period: batch.pay_period,
        batch:
      )
      digest = Digest::SHA256.hexdigest(binary)

      PayrollExport.transaction do
        export = PayrollExport.new(
          pay_period: batch.pay_period,
          exported_by: actor,
          is_final: false,
          file_format: file_format,
          exported_at: Time.current,
          payroll_input_batch_id: batch.id,
          validation_summary: snapshot,
          original_filename: filename,
          byte_size: binary.bytesize,
          content_sha256: digest
        )
        export.export_file.attach(io: StringIO.new(binary), filename:, content_type:)
        export.save!
        export
      end
    end

    private

    attr_reader :batch, :actor, :file_format
  end
end

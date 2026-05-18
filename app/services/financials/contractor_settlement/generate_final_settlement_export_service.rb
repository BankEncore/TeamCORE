# frozen_string_literal: true

require "digest"
require "stringio"

module Financials
  module ContractorSettlement
    class GenerateFinalSettlementExportService
      class Error < StandardError; end

      def self.call(run:, actor:, file_format: "csv")
        new(run:, actor:, file_format:).call
      end

      def initialize(run:, actor:, file_format:)
        @run = run
        @actor = actor
        @file_format = file_format.to_s.downcase
      end

      def call
        raise Error, "Final settlement export requires a finalized run." unless run.status == "finalized"
        unless PayrollExport::FILE_FORMATS.include?(file_format)
          raise Error, "Unsupported file format."
        end

        binary, content_type, filename = SettlementExportFileBuilder.call(run:, format: file_format, draft: false)
        snapshot = SettlementExportValidationSnapshot.call(run:)
        digest = Digest::SHA256.hexdigest(binary)

        ContractorSettlementExport.transaction do
          export = ContractorSettlementExport.new(
            contractor_settlement_run: run,
            exported_by: actor,
            is_final: true,
            file_format: file_format,
            exported_at: Time.current,
            validation_summary: snapshot,
            original_filename: filename,
            byte_size: binary.bytesize,
            content_sha256: digest
          )
          export.export_file.attach(io: StringIO.new(binary), filename:, content_type:)
          export.save!

          ContractorSettlementRunEvent.create!(
            contractor_settlement_run: run,
            event_type: "final_exported",
            actor: actor,
            reason: "format=#{file_format} export_seq=#{export.export_sequence}"
          )
          export
        end
      end

      private

      attr_reader :run, :actor, :file_format
    end
  end
end

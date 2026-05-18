# frozen_string_literal: true

require "digest"
require "stringio"

module Financials
  module ContractorSettlement
    class GenerateDraftSettlementExportService
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
        unless run.status.in?(%w[calculated finalized])
          raise Error, "Draft settlement export requires a calculated or finalized run."
        end
        unless PayrollExport::FILE_FORMATS.include?(file_format)
          raise Error, "Unsupported file format."
        end

        binary, content_type, filename = SettlementExportFileBuilder.call(run:, format: file_format, draft: true)
        snapshot = SettlementExportValidationSnapshot.call(run:)
        digest = Digest::SHA256.hexdigest(binary)

        ContractorSettlementExport.transaction do
          export = ContractorSettlementExport.new(
            contractor_settlement_run: run,
            exported_by: actor,
            is_final: false,
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
            event_type: "draft_exported",
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

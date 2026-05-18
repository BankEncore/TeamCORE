# frozen_string_literal: true

require "csv"

module Financials
  module ContractorSettlement
    # Builds CSV/XLSX for contractor settlement interchange (TC-20); columns documented in
    # docs/roadmap/phase-5-payroll-time-leave/phase-5-tc-20-export-column-contract.md.
    class SettlementExportFileBuilder
      COLUMN_KEYS = %w[
        contractor_settlement_run_id
        agency_id
        period_start_on
        period_end_on
        engagement_id
        team_member_number
        party_id
        party_display_name
        gross_commission_cents
        charge_deductions_cents
        manual_adjustment_positive_cents
        manual_adjustment_negative_cents
        net_settlement_cents
      ].freeze

      FORMATS = PayrollExport::FILE_FORMATS

      class << self
        def call(run:, format:, draft: false)
          new(run:, format: format.to_s.downcase, draft:).call
        end

        def filename_for(run:, format:, draft:)
          fmt = format.to_s.downcase
          raise ArgumentError, "unsupported format" unless FORMATS.include?(fmt)

          ext = fmt == "xlsx" ? "xlsx" : "csv"
          kind = draft ? "draft" : "final"
          "contractor-settlement-run-#{run.id}-#{kind}.#{ext}"
        end

        def mime_for(format)
          format.to_s.downcase == "xlsx" ? XLSX_CONTENT_TYPE : CSV_CONTENT_TYPE
        end

        CSV_CONTENT_TYPE = "text/csv; charset=utf-8"
        XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      end

      def initialize(run:, format:, draft: false)
        @run = run
        @format = format
        @draft = draft
        raise ArgumentError, "unsupported format" unless FORMATS.include?(@format)
      end

      def call
        rows = build_rows
        binary =
          case format
          when "csv" then encode_csv(rows)
          when "xlsx" then encode_xlsx(rows)
          end
        [ binary, self.class.mime_for(format), self.class.filename_for(run:, format:, draft:) ]
      end

      private

      attr_reader :run, :format, :draft

      def build_rows
        run.contractor_settlement_lines.includes(engagement: { team_member: :party }).order(:engagement_id, :id).map do |ln|
          eng = ln.engagement
          tm = eng.team_member
          party = tm.party
          {
            "contractor_settlement_run_id" => run.id,
            "agency_id" => run.agency_id,
            "period_start_on" => run.period_start_on.iso8601,
            "period_end_on" => run.period_end_on.iso8601,
            "engagement_id" => eng.id,
            "team_member_number" => tm.team_member_number,
            "party_id" => party.id,
            "party_display_name" => party.display_name,
            "gross_commission_cents" => ln.gross_commission_cents,
            "charge_deductions_cents" => ln.charge_deductions_cents,
            "manual_adjustment_positive_cents" => ln.manual_adjustment_positive_cents,
            "manual_adjustment_negative_cents" => ln.manual_adjustment_negative_cents,
            "net_settlement_cents" => ln.net_settlement_cents
          }
        end
      end

      def encode_csv(rows)
        CSV.generate(encoding: Encoding::UTF_8) do |csv|
          csv << COLUMN_KEYS
          rows.each { |h| csv << COLUMN_KEYS.map { |k| h[k] } }
        end
      end

      def encode_xlsx(rows)
        require "axlsx"

        package = Axlsx::Package.new
        package.workbook.add_worksheet(name: "SettlementExport") do |sheet|
          sheet.add_row(COLUMN_KEYS)
          rows.each { |h| sheet.add_row(COLUMN_KEYS.map { |k| h[k] }) }
        end
        package.to_stream.read.force_encoding(Encoding::BINARY)
      end
    end
  end
end

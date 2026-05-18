# frozen_string_literal: true

require "csv"
require "stringio"

module Payroll
  # Builds outbound CSV/XLSX for TC-20 / TC-21 interchange (see docs/roadmap/phase-5-payroll-time-leave/phase-5-tc-20-export-column-contract.md).
  class PayrollExportFileBuilder
    COLUMN_KEYS = %w[
      pay_period_id
      pay_period_start_on
      pay_period_end_on
      payroll_input_batch_id
      payroll_input_batch_reference
      engagement_id
      team_member_number
      party_id
      party_display_name
      earning_code
      direction
      hours
      amount
      currency
    ].freeze

    FORMATS = PayrollExport::FILE_FORMATS

    class << self
      def call(batch:, format:, draft: false)
        new(batch:, format: format.to_s.downcase, draft:).call
      end

      def filename_for(batch:, format:, draft:)
        fmt = format.to_s.downcase
        raise ArgumentError, "unsupported format" unless FORMATS.include?(fmt)

        ext = fmt == "xlsx" ? "xlsx" : "csv"
        slug = batch.reference_number.to_s.gsub(/[^\w.-]+/, "_")
        kind = draft ? "draft" : "final"
        "payroll-input-#{slug}-#{kind}.#{ext}"
      end

      def mime_for(format)
        format.to_s.downcase == "xlsx" ? XLSX_CONTENT_TYPE : CSV_CONTENT_TYPE
      end

      CSV_CONTENT_TYPE = "text/csv; charset=utf-8"
      XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    def initialize(batch:, format:, draft: false)
      @batch = batch
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
      [ binary, self.class.mime_for(format), self.class.filename_for(batch:, format:, draft: draft) ]
    end

    private

    attr_reader :batch, :format, :draft

    def build_rows
      pp = batch.pay_period
      batch.payroll_input_rows.includes(engagement: { team_member: :party }).order(:engagement_id, :earning_code, :id).map do |r|
        eng = r.engagement
        tm = eng.team_member
        party = tm.party
        {
          "pay_period_id" => pp.id,
          "pay_period_start_on" => pp.start_on.iso8601,
          "pay_period_end_on" => pp.end_on.iso8601,
          "payroll_input_batch_id" => batch.id,
          "payroll_input_batch_reference" => batch.reference_number,
          "engagement_id" => eng.id,
          "team_member_number" => tm.team_member_number,
          "party_id" => party.id,
          "party_display_name" => party.display_name,
          "earning_code" => r.earning_code,
          "direction" => r.direction,
          "hours" => r.hours&.to_s("F"),
          "amount" => r.amount&.to_s("F"),
          "currency" => r.currency
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
      package.workbook.add_worksheet(name: "PayrollExport") do |sheet|
        sheet.add_row(COLUMN_KEYS)
        rows.each { |h| sheet.add_row(COLUMN_KEYS.map { |k| h[k] }) }
      end
      package.to_stream.read.force_encoding(Encoding::BINARY)
    end
  end
end

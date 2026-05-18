# frozen_string_literal: true

module Financials
  module ContractorSettlement
    class SettlementExportValidationSnapshot
      def self.call(run:)
        lines = run.contractor_settlement_lines
        warnings = []
        lines.each do |ln|
          warnings << "engagement #{ln.engagement_id} net settlement is zero" if ln.net_settlement_cents.to_i.zero?
        end

        {
          "generated_at" => Time.current.utc.iso8601,
          "line_count" => lines.count,
          "warnings" => warnings.first(100)
        }
      end
    end
  end
end

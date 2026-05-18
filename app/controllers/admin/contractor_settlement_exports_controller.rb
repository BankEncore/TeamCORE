# frozen_string_literal: true

module Admin
  class ContractorSettlementExportsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_export

    def download
      unless @export.export_file.attached?
        redirect_back fallback_location: admin_root_path, alert: "Export file is missing."
        return
      end

      send_data @export.export_file.download,
        filename: @export.suggested_download_filename,
        type: @export.export_file.content_type,
        disposition: :attachment
    end

    private

    def set_export
      @export =
        ContractorSettlementExport
          .joins(:contractor_settlement_run)
          .where(contractor_settlement_runs: { agency_id: current_agency.id })
          .find(params[:id])
    end
  end
end

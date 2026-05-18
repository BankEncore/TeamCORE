# frozen_string_literal: true

module Admin
  class PayrollExportsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :require_payroll_export_access!
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

    def require_payroll_export_access!
      return if Payroll::Access.can_manage_payroll_input?(user: current_user, agency: current_agency)

      redirect_to admin_root_path, alert: "Not permitted."
    end

    def set_export
      @export = PayrollExport.joins(:pay_period).where(pay_periods: { agency_id: current_agency.id }).find(params[:id])
    end
  end
end

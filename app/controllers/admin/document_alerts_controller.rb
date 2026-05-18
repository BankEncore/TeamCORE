# frozen_string_literal: true

module Admin
  # Read-only aggregate of derived document alerts across engagements (TC-07).
  class DocumentAlertsController < Admin::BaseController
    include Admin::ReportParamParsing

    before_action :require_current_agency!

    def index
      @as_of_date = parse_report_date(params[:as_of_date]) || Date.current

      dt_id = parse_non_negative_int_param(params[:document_type_id])
      tm_id = parse_non_negative_int_param(params[:team_member_id])
      cutoff = parse_report_date(params[:expires_on_or_before])

      @flat_alert_rows =
        Documents::FlatAlertRows.build(
          agency_id: current_agency.id,
          as_of_date: @as_of_date,
          include_terminal: include_terminal_engagements?,
          engagement_status: params[:engagement_status].presence,
          relationship_type: params[:relationship_type].presence,
          alert_type: params[:alert_type].presence,
          severity: params[:severity].presence,
          document_type_id: dt_id,
          team_member_id: tm_id,
          expires_on_or_before: cutoff
        )

      type_ids = @flat_alert_rows.map { |r| r.alert.document_type_id }.uniq
      @document_types_by_id = DocumentType.where(id: type_ids).index_by(&:id)
    end

    private

    def include_terminal_engagements?
      ActiveModel::Type::Boolean.new.cast(params[:include_terminal])
    end
  end
end

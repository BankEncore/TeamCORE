# frozen_string_literal: true

module Admin
  module Reports
    # Document compliance exceptions (evaluator-driven; TC-12).
    class DocumentComplianceController < Admin::Reports::BaseController
      FlatAlertRow = Struct.new(:engagement, :alert, keyword_init: true)

      before_action :require_current_agency!

      def index
        @as_of_date = parse_report_date(params[:as_of_date]) || Date.current

        engagements = Engagement.where(agency_id: current_agency.id)
        engagements =
          engagements.where.not(status: Engagement::TERMINAL_STATUSES) unless include_terminal_engagements?

        engagements = engagements.where(status: params[:engagement_status]) if params[:engagement_status].present?
        engagements = engagements.where(relationship_type: params[:relationship_type]) if params[:relationship_type].present?

        engagements = engagements.includes(team_member: :party).order(:id).to_a

        rows = engagements.flat_map do |engagement|
          result = Documents::ReadinessEvaluator.new(engagement: engagement, as_of_date: @as_of_date).call
          result.alerts.map { |alert| FlatAlertRow.new(engagement: engagement, alert: alert) }
        end

        rows.select! { |r| r.alert.alert_type == params[:alert_type] } if params[:alert_type].present?
        rows.select! { |r| r.alert.severity == params[:severity] } if params[:severity].present?

        if (dt_id = parse_non_negative_int_param(params[:document_type_id]))
          rows.select! { |r| r.alert.document_type_id == dt_id }
        end

        if (tm_id = parse_non_negative_int_param(params[:team_member_id]))
          rows.select! { |r| r.alert.team_member_id == tm_id }
        end

        if (cutoff = parse_report_date(params[:expires_on_or_before]))
          rows.select! { |r| r.alert.expires_on.present? && r.alert.expires_on <= cutoff }
        end

        @flat_rows = sort_flat_rows(rows)
        type_ids = @flat_rows.map { |r| r.alert.document_type_id }.uniq
        @document_types_by_id = DocumentType.where(id: type_ids).index_by(&:id)
      end

      private

      def include_terminal_engagements?
        ActiveModel::Type::Boolean.new.cast(params[:include_terminal])
      end

      def sort_flat_rows(rows)
        severity_rank = Documents::ReadinessEvaluator::SEVERITY_RANK
        type_rank = Documents::ReadinessEvaluator::ALERT_TYPE_RANK
        type_ids = rows.map { |r| r.alert.document_type_id }.uniq
        codes = DocumentType.where(id: type_ids).pluck(:id, :code).to_h

        rows.sort_by do |r|
          a = r.alert
          expires_jd =
            if a.expires_on.present?
              a.expires_on.jd.to_f
            else
              Float::INFINITY
            end

          [
            severity_rank.fetch(a.severity, 99),
            type_rank.fetch(a.alert_type, 99),
            expires_jd,
            codes.fetch(a.document_type_id, "").to_s.downcase,
            a.document_requirement_id,
            r.engagement.id
          ]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  module Reports
    # Contractor-class engagements with document alert exceptions (TC-12 / PR F).
    class ContractorDocumentationController < Admin::Reports::BaseController
      FlatAlertRow = Struct.new(:engagement, :alert, keyword_init: true)

      CONTRACTOR_REL_TYPES = %w[individual_contractor contractor_organization subcontractor].freeze

      before_action :require_current_agency!

      def index
        @as_of_date = parse_report_date(params[:as_of_date]) || Date.current
        @document_categories =
          DocumentType.where(agency_id: current_agency.id).distinct.order(:category).pluck(:category)
        @contractor_rel_types = CONTRACTOR_REL_TYPES

        engagements =
          Engagement
            .where(agency_id: current_agency.id, relationship_type: CONTRACTOR_REL_TYPES)
            .includes(team_member: :party)
            .order(:id)
            .to_a

        engagements =
          engagements.reject { |e| Engagement::TERMINAL_STATUSES.include?(e.status) } unless include_terminal_engagements?

        engagements.select! { |e| e.relationship_type == params[:relationship_type] } if params[:relationship_type].present?

        rows = engagements.flat_map do |engagement|
          result = Documents::ReadinessEvaluator.new(engagement: engagement, as_of_date: @as_of_date).call
          result.alerts.map { |alert| FlatAlertRow.new(engagement: engagement, alert: alert) }
        end

        rows.select! { |r| r.alert.alert_type == params[:alert_type] } if params[:alert_type].present?
        rows.select! { |r| r.alert.severity == params[:severity] } if params[:severity].present?

        if (cat = params[:document_category]).present?
          type_ids = DocumentType.where(agency_id: current_agency.id, category: cat).pluck(:id)
          rows.select! { |r| type_ids.include?(r.alert.document_type_id) }
        end

        if (rs = params[:readiness_status]).present?
          rows.select! do |r|
            Documents::ReadinessEvaluator
              .new(engagement: r.engagement, as_of_date: @as_of_date)
              .call
              .readiness_status == rs
          end
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
          expires_jd = a.expires_on.present? ? a.expires_on.jd.to_f : Float::INFINITY
          [
            severity_rank.fetch(a.severity, 99),
            type_rank.fetch(a.alert_type, 99),
            expires_jd,
            codes.fetch(a.document_type_id, "").to_s.downcase,
            r.engagement.id
          ]
        end
      end
    end
  end
end

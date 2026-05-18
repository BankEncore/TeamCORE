# frozen_string_literal: true

module Documents
  # Shared evaluator-backed alert rows for document alerts index (TC-07) and
  # document compliance report (TC-12). Keeps filtering and sort order aligned.
  module FlatAlertRows
    FlatAlertRow = Struct.new(:engagement, :alert, keyword_init: true)

    class << self
      def build(
        agency_id:,
        as_of_date:,
        include_terminal: false,
        engagement_status: nil,
        relationship_type: nil,
        alert_type: nil,
        severity: nil,
        document_type_id: nil,
        team_member_id: nil,
        expires_on_or_before: nil
      )
        engagements = Engagement.where(agency_id: agency_id)
        engagements =
          engagements.where.not(status: Engagement::TERMINAL_STATUSES) unless include_terminal

        if engagement_status.present?
          engagements = engagements.where(status: engagement_status)
        end

        engagements = engagements.where(relationship_type: relationship_type) if relationship_type.present?

        engagements = engagements.includes(team_member: :party).order(:id).to_a

        rows = engagements.flat_map do |engagement|
          result = Documents::ReadinessEvaluator.new(engagement: engagement, as_of_date: as_of_date).call
          result.alerts.map { |alert| FlatAlertRow.new(engagement: engagement, alert: alert) }
        end

        rows.select! { |r| r.alert.alert_type == alert_type } if alert_type.present?
        rows.select! { |r| r.alert.severity == severity } if severity.present?

        if document_type_id.present?
          rows.select! { |r| r.alert.document_type_id == document_type_id }
        end

        if team_member_id.present?
          rows.select! { |r| r.alert.team_member_id == team_member_id }
        end

        if expires_on_or_before.present?
          rows.select! { |r| r.alert.expires_on.present? && r.alert.expires_on <= expires_on_or_before }
        end

        sort_flat_rows(rows)
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
            r.engagement.id,
            r.engagement.team_member_id.to_i
          ]
        end
      end
    end
  end
end

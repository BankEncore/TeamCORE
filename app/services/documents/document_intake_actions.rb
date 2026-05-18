# frozen_string_literal: true

module Documents
  # Read-time CTAs from evaluator rows → concrete admin routes (TC-UX-DOC-01).
  class DocumentIntakeActions
    include Rails.application.routes.url_helpers

    Action = Data.define(
      :kind,
      :primary_label,
      :primary_href,
      :secondary_label,
      :secondary_href
    )

    class << self
      PseudoEvaluation = Struct.new(
        :requirement_outcome,
        :document_requirement_id,
        :document_type_id,
        :document_record_id,
        keyword_init: true
      )

      def from_requirement_evaluation(evaluation, **kwargs)
        new.dispatch(evaluation, **kwargs)
      end

      def from_alert_result(alert, **kwargs)
        outcome =
          case alert.alert_type
          when "missing" then "missing"
          when "pending_verification" then "pending_verification"
          when "rejected" then "rejected"
          when "expired" then "expired"
          when "expiring_soon" then "expiring_soon"
          else "not_applicable"
          end

        pseudo = PseudoEvaluation.new(
          requirement_outcome: outcome,
          document_requirement_id: alert.document_requirement_id,
          document_type_id: alert.document_type_id,
          document_record_id: alert.document_record_id
        )

        new.dispatch(pseudo, **kwargs)
      end

      def noop
        Action.new(kind: :none, primary_label: nil, primary_href: nil, secondary_label: nil, secondary_href: nil)
      end
    end

    def dispatch(evaluation, team_member:, engagement:, document_type:, return_to:, team360_return_to: nil, as_of_date: Date.current)
      rt = nav_query(return_to: return_to, team360_return_to: team360_return_to)
      tm_secondary = team360_secondary(
        team_member: team_member,
        engagement: engagement,
        return_to: return_to,
        team360_return_to: team360_return_to,
        as_of_date: as_of_date
      )

      dtype_label = document_type&.name.presence || "document"
      outcome = evaluation.requirement_outcome.to_s

      case outcome
      when "missing"
        Action.new(
          kind: :add_document,
          primary_label: "Add #{dtype_label}",
          primary_href: new_admin_document_record_path(rt.merge(
            team_member_id: team_member.id,
            engagement_id: engagement.id,
            document_type_id: evaluation.document_type_id,
            document_requirement_id: evaluation.document_requirement_id,
            intake: "missing_requirement"
          )),
          secondary_label: tm_secondary&.fetch(:label),
          secondary_href: tm_secondary&.fetch(:href)
        )
      when "pending_verification"
        rid = evaluation.document_record_id
        unless rid
          return Action.new(
            kind: :review,
            primary_label: "Pending review queue",
            primary_href: admin_document_reviews_path(rt),
            secondary_label: tm_secondary&.fetch(:label),
            secondary_href: tm_secondary&.fetch(:href)
          )
        end

        Action.new(
          kind: :review,
          primary_label: "Review document",
          primary_href: admin_document_record_path(rid, rt),
          secondary_label: tm_secondary&.fetch(:label),
          secondary_href: tm_secondary&.fetch(:href)
        )
      when "rejected"
        Action.new(
          kind: :upload_corrected,
          primary_label: "Upload corrected document",
          primary_href: new_admin_document_record_path(rt.merge(
            team_member_id: team_member.id,
            engagement_id: engagement.id,
            document_type_id: evaluation.document_type_id,
            document_requirement_id: evaluation.document_requirement_id,
            intake: "replace_rejected"
          )),
          secondary_label: tm_secondary&.fetch(:label),
          secondary_href: tm_secondary&.fetch(:href)
        )
      when "expired", "expiring_soon"
        view_record_secondary =
          if evaluation.document_record_id
            { label: "View record", href: admin_document_record_path(evaluation.document_record_id, rt) }
          end

        Action.new(
          kind: :add_renewal,
          primary_label: "Add renewal",
          primary_href: new_admin_document_record_path(rt.merge(
            team_member_id: team_member.id,
            engagement_id: engagement.id,
            document_type_id: evaluation.document_type_id,
            document_requirement_id: evaluation.document_requirement_id,
            intake: "renew_expired"
          )),
          secondary_label: view_record_secondary&.dig(:label) || tm_secondary&.fetch(:label),
          secondary_href: view_record_secondary&.dig(:href) || tm_secondary&.fetch(:href)
        )
      when "satisfied"
        rid = evaluation.document_record_id
        return self.class.noop unless rid

        Action.new(
          kind: :view,
          primary_label: "View document",
          primary_href: admin_document_record_path(rid, rt),
          secondary_label: tm_secondary&.fetch(:label),
          secondary_href: tm_secondary&.fetch(:href)
        )
      else
        self.class.noop
      end
    end

    private

    def nav_query(return_to:, team360_return_to:)
      q = {}
      q[:return_to] = return_to if return_to.present?
      q[:team360_return_to] = team360_return_to if team360_return_to.present?
      q
    end

    def team360_secondary(team_member:, engagement:, return_to:, team360_return_to:, as_of_date:)
      return nil unless team_member && engagement

      extras = {
        engagement_id: engagement.id,
        as_of_date: as_of_date&.iso8601
      }.compact
      extras[:return_to] = return_to if return_to.present?
      extras[:team360_return_to] = team360_return_to if team360_return_to.present?

      {
        label: "Open Team360",
        href: admin_team_member_team360_path(team_member, extras)
      }
    end
  end
end

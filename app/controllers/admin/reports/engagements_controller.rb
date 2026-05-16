# frozen_string_literal: true

module Admin
  module Reports
    class EngagementsController < Admin::Reports::BaseController
      before_action :require_current_agency!

      def index
        @as_of_date = parse_report_date(params[:as_of_date]) || Date.current
        engs =
          Engagement
            .where(agency_id: current_agency.id)
            .includes(
              team_member: :party,
              engagement_organization_placements: %i[department location team],
              engagement_supervision_assignments: { supervisor_engagement: { team_member: :party } }
            )

        engs = engs.where(relationship_type: params[:relationship_type]) if params[:relationship_type].present?
        engs = engs.where(status: params[:status]) if params[:status].present?

        if (from = parse_report_date(params[:start_on_from]))
          engs = engs.where(start_on: from..)
        end
        if (to = parse_report_date(params[:start_on_to]))
          engs = engs.where(start_on: ..to)
        end

        if (did = parse_non_negative_int_param(params[:department_id]))
          engs =
            effective_placement_join(engs, @as_of_date).where(engagement_organization_placements: { department_id: did }).distinct
        end

        if (lid = parse_non_negative_int_param(params[:location_id]))
          engs =
            effective_placement_join(engs, @as_of_date).where(engagement_organization_placements: { location_id: lid }).distinct
        end

        if (tid = parse_non_negative_int_param(params[:team_id]))
          engs =
            effective_placement_join(engs, @as_of_date).where(engagement_organization_placements: { team_id: tid }).distinct
        end

        if (sup = parse_non_negative_int_param(params[:supervisor_engagement_id]))
          engs =
            engs.joins(:engagement_supervision_assignments).where(
              engagement_supervision_assignments: { supervisor_engagement_id: sup }
            ).where(
              "engagement_supervision_assignments.effective_start_on <= ? AND (engagement_supervision_assignments.effective_end_on IS NULL OR engagement_supervision_assignments.effective_end_on >= ?)",
              @as_of_date,
              @as_of_date
            ).distinct
        end

        @engagements = engs.order(:id).to_a
        @readiness_by_engagement_id = {}
        @engagements.each do |e|
          @readiness_by_engagement_id[e.id] =
            Documents::ReadinessEvaluator.new(engagement: e, as_of_date: @as_of_date).call.readiness_status
        end
      end

      private

      def effective_placement_join(scope, as_of)
        scope.joins(:engagement_organization_placements).where(
          "engagement_organization_placements.effective_start_on <= ? AND (engagement_organization_placements.effective_end_on IS NULL OR engagement_organization_placements.effective_end_on >= ?)",
          as_of,
          as_of
        )
      end
    end
  end
end

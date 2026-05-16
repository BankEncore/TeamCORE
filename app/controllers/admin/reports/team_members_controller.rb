# frozen_string_literal: true

module Admin
  module Reports
    # Operational roster: team members with drill-through to Team360 (TC-12).
    class TeamMembersController < Admin::Reports::BaseController
      before_action :require_current_agency!

      def index
        @as_of_date = parse_report_date(params[:as_of_date]) || Date.current
        tms = TeamMember.where(agency_id: current_agency.id).includes(:party, engagements: %i[
          engagement_organization_placements
          engagement_supervision_assignments
        ])

        if (pt = params[:party_type]).present?
          tms = tms.joins(:party).where(parties: { party_type: pt })
        end

        if (st = params[:team_member_status]).present?
          tms = tms.where(status: st)
        end

        if (rt = params[:engagement_relationship_type]).present?
          tms = tms.joins(:engagements).where(engagements: { relationship_type: rt }).distinct
        end

        if (es = params[:engagement_status]).present?
          tms = tms.joins(:engagements).where(engagements: { status: es }).distinct
        end

        if (did = parse_non_negative_int_param(params[:department_id]))
          tms = effective_placement_join(tms, @as_of_date).where(engagement_organization_placements: { department_id: did }).distinct
        end

        if (lid = parse_non_negative_int_param(params[:location_id]))
          tms = effective_placement_join(tms, @as_of_date).where(engagement_organization_placements: { location_id: lid }).distinct
        end

        if (tid = parse_non_negative_int_param(params[:team_id]))
          tms = effective_placement_join(tms, @as_of_date).where(engagement_organization_placements: { team_id: tid }).distinct
        end

        if (sup = parse_non_negative_int_param(params[:supervisor_engagement_id]))
          tms =
            tms.joins(engagements: :engagement_supervision_assignments).where(
              engagement_supervision_assignments: { supervisor_engagement_id: sup }
            ).where(
              "engagement_supervision_assignments.effective_start_on <= ? AND (engagement_supervision_assignments.effective_end_on IS NULL OR engagement_supervision_assignments.effective_end_on >= ?)",
              @as_of_date,
              @as_of_date
            ).distinct
        end

        rows = tms.order(:id).map { |tm| roster_row_for(tm, @as_of_date) }

        if (rs = params[:document_readiness_status]).present?
          rows.select! { |r| r[:readiness_status].to_s == rs }
        end

        @roster_rows = rows
      end

      private

      def effective_placement_join(scope, as_of)
        scope.joins(engagements: :engagement_organization_placements).where(
          "engagement_organization_placements.effective_start_on <= ? AND (engagement_organization_placements.effective_end_on IS NULL OR engagement_organization_placements.effective_end_on >= ?)",
          as_of,
          as_of
        )
      end

      def roster_row_for(team_member, as_of_date)
        party = team_member.party
        focused =
          Team360::FocusedEngagementResolver.call(team_member: team_member, preferred_engagement_id: nil)

        readiness =
          if focused
            Documents::ReadinessEvaluator.new(engagement: focused, as_of_date: as_of_date).call
          end

        {
          team_member: team_member,
          party_type: party.party_type,
          display_name: party.display_name,
          focused_engagement: focused,
          engagement_summary: engagement_summary_label(team_member, focused),
          readiness_status: readiness&.readiness_status,
          alert_count: readiness ? readiness.alerts.size : 0
        }
      end

      def engagement_summary_label(team_member, focused)
        return "—" unless focused

        "#{focused.relationship_type} (#{focused.status})"
      end
    end
  end
end

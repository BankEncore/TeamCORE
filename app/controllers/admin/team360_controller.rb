# frozen_string_literal: true

module Admin
  class Team360Controller < Admin::BaseController
    include Admin::ReportParamParsing

    before_action :require_current_agency!
    before_action :set_team_member

    def show
      @as_of_date = parse_report_date(params[:as_of_date]) || Date.current
      @snapshot =
        Team360::ProfileAssembler.new(
          team_member: @team_member,
          agency: current_agency,
          current_user: current_user,
          as_of_date: @as_of_date,
          focused_engagement_id: engagement_focus_param
        ).call

      if @snapshot.focused_engagement_id.present?
        eng =
          Engagement
            .where(agency_id: current_agency.id)
            .includes(
              :team_member,
              :engagement_organization_placements,
              :engagement_supervision_assignments,
              :contractor_charges,
              :contractor_settlement_lines
            )
            .find_by(id: @snapshot.focused_engagement_id)
        if eng && @snapshot.readiness_result
          @engagement_setup_checklist =
            Admin::EngagementSetupChecklistPresenter.new(
              engagement: eng,
              document_readiness: @snapshot.readiness_result,
              as_of_date: @as_of_date,
              placement_rows: eng.engagement_organization_placements.order(:effective_start_on),
              supervision_rows: eng.engagement_supervision_assignments.order(:effective_start_on),
              workforce_financial_assignment: CompensationPlanAssignment.current_for_engagement(eng)
            )
        end
      end
    end

    private

    def set_team_member
      @team_member =
        TeamMember
          .where(agency_id: current_agency.id)
          .includes(
            party: :party_contact_methods,
            engagements: [
              { engagement_organization_placements: %i[department location team] },
              { engagement_supervision_assignments: { supervisor_engagement: { team_member: :party } } }
            ]
          )
          .find(params[:team_member_id])
    end

    def engagement_focus_param
      v = params[:engagement_id]
      return nil if v.blank?
      return nil unless v.to_s.match?(/\A\d+\z/)

      v.to_i
    end
  end
end

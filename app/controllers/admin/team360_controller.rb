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

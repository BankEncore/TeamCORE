# frozen_string_literal: true

module Admin
  class TeamMembersController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_team_member, only: %i[show edit update]

    def index
      @team_members = TeamMember.where(agency_id: current_agency.id).includes(:party).order(:id)
    end

    def show
      @incoming_subcontractor_rels =
        PartyRelationship
          .where(
            agency_id: current_agency.id,
            relationship_type: "subcontractor",
            target_party_id: @team_member.party_id
          )
          .includes(:source_party)
          .order(:id)
    end

    def new
      @team_member = TeamMember.new(agency: current_agency)
      load_eligible_parties
      if params[:party_id].present?
        pid = params[:party_id].to_i
        party = @eligible_parties.find { |p| p.id == pid }
        @team_member.party_id = party.id if party
      end
    end

    def create
      @team_member = TeamMember.new(team_member_params.merge(agency: current_agency))
      if @team_member.save
        redirect_to admin_team_member_path(@team_member), notice: "Team member created."
      else
        load_eligible_parties
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @team_member.update(team_member_update_params)
        redirect_to admin_team_member_path(@team_member), notice: "Team member updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_team_member
      @team_member = TeamMember.where(agency_id: current_agency.id).find(params[:id])
    end

    def load_eligible_parties
      used_party_ids = TeamMember.where(agency_id: current_agency.id).where.not(party_id: nil).pluck(:party_id)

      @eligible_parties =
        Party.where(agency_id: current_agency.id)
          .includes(:person_profile, :organization_profile)
          .where.not(id: used_party_ids)
          .order(:display_name, :id)
          .select(&:identity_complete?)
    end

    def team_member_params
      params.require(:team_member).permit(:party_id, :team_member_number, :status)
    end

    def team_member_update_params
      params.require(:team_member).permit(:team_member_number, :status)
    end
  end
end

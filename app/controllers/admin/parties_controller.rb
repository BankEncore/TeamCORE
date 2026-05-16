# frozen_string_literal: true

module Admin
  class PartiesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_party, only: %i[show edit update]

    def index
      @parties = Party.where(agency_id: current_agency.id).order(:display_name, :id)
    end

    def show
      @outgoing_subcontractors =
        @party.outgoing_party_relationships
          .where(relationship_type: "subcontractor")
          .includes(:target_party)
          .order(:id)
      @incoming_subcontractors =
        @party.incoming_party_relationships
          .where(relationship_type: "subcontractor")
          .includes(:source_party)
          .order(:id)
      @can_source_subcontractor_relationships = @party.subcontractor_source_contractor_capable_for_agency?(current_agency)

      @team_member = TeamMember.find_by(agency_id: current_agency.id, party_id: @party.id)
      @party_eligible_for_new_team_member = @party.identity_complete? && @team_member.nil?
      @engagements = @team_member ? @team_member.engagements.order(:id).to_a : []
      @contact_methods = @party.party_contact_methods.order(:contact_type, :id).to_a
      @document_records =
        @party
          .document_records
          .where(agency_id: current_agency.id)
          .includes(:document_type)
          .order(id: :desc)
          .limit(10)
          .to_a
      @document_new_params = document_new_query_params
    end

    def new_person
      @party = Party.new(agency: current_agency, party_type: "person", status: "active")
      @party.build_person_profile
    end

    def create_person
      attrs = party_base_params.merge(agency: current_agency, party_type: "person")
      attrs[:status] = attrs[:status].presence || "active"
      @party = Party.new(attrs)
      @party.build_person_profile(person_profile_params)
      if @party.save
        redirect_to admin_party_path(@party), notice: "Person party created."
      else
        render :new_person, status: :unprocessable_entity
      end
    end

    def new_organization
      @party = Party.new(agency: current_agency, party_type: "organization", status: "active")
      @party.build_organization_profile
    end

    def create_organization
      attrs = party_base_params.merge(agency: current_agency, party_type: "organization")
      attrs[:status] = attrs[:status].presence || "active"
      @party = Party.new(attrs)
      @party.build_organization_profile(organization_profile_params)
      if @party.save
        redirect_to admin_party_path(@party), notice: "Organization party created."
      else
        render :new_organization, status: :unprocessable_entity
      end
    end

    def edit
      @party.build_person_profile if @party.person? && @party.person_profile.blank?
      @party.build_organization_profile if @party.organization? && @party.organization_profile.blank?
    end

    def update
      if @party.update(party_update_params)
        redirect_to admin_party_path(@party), notice: "Party updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_party
      scope = Party.where(agency_id: current_agency.id)
      if action_name == "show"
        scope = scope.includes(:person_profile, :organization_profile, :party_contact_methods)
      end
      @party = scope.find(params[:id])
    end

    def document_new_query_params
      h = { party_id: @party.id }
      if @team_member
        h[:team_member_id] = @team_member.id
        h[:engagement_id] = @engagements.first.id if @engagements.one?
      end
      h
    end

    def party_base_params
      params.require(:party).permit(:display_name, :external_reference, :notes, :status)
    end

    def person_profile_params
      params.require(:party).require(:person_profile).permit(
        :first_name, :last_name, :middle_name, :preferred_name, :suffix
      )
    end

    def organization_profile_params
      params.require(:party).require(:organization_profile).permit(
        :legal_name, :trade_name, :organization_kind
      )
    end

    def party_update_params
      base = %i[display_name external_reference notes status]
      if @party.person?
        params.require(:party).permit(
          *base,
          person_profile_attributes: %i[id first_name last_name middle_name preferred_name suffix]
        )
      else
        params.require(:party).permit(
          *base,
          organization_profile_attributes: %i[id legal_name trade_name organization_kind]
        )
      end
    end
  end
end

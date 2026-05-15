# frozen_string_literal: true

module Admin
  class PartiesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_party, only: %i[show edit update]

    def index
      @parties = Party.where(agency_id: current_agency.id).order(:display_name, :id)
    end

    def show
    end

    def new_person
      @party = Party.new(agency: current_agency, party_type: "person", status: "active")
      @party.build_person_profile
    end

    def create_person
      @party = Party.new(party_base_params.merge(agency: current_agency, party_type: "person"))
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
      @party = Party.new(party_base_params.merge(agency: current_agency, party_type: "organization"))
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
      @party = Party.where(agency_id: current_agency.id).find(params[:id])
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

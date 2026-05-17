# frozen_string_literal: true

module Admin
  class PartyContactMethodsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_party
    before_action :set_party_contact_method, only: %i[edit update]

    helper_method :current_party_team_member_for_nav

    def new
      @party_contact_method = @party.party_contact_methods.build(status: "active")
    end

    def create
      @party_contact_method = @party.party_contact_methods.build(party_contact_method_params)
      if save_with_primary_demotion!(@party_contact_method)
        redirect_to admin_party_path(@party), notice: "Contact method created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @party_contact_method.assign_attributes(party_contact_method_params)
      if save_with_primary_demotion!(@party_contact_method)
        redirect_to admin_party_path(@party), notice: "Contact method updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def current_party_team_member_for_nav
      @current_party_team_member_for_nav ||=
        TeamMember.find_by(agency_id: current_agency.id, party_id: @party.id)
    end

    def set_party
      @party = Party.where(agency_id: current_agency.id).find(params[:party_id])
    end

    def set_party_contact_method
      @party_contact_method = @party.party_contact_methods.find(params[:id])
    end

    def party_contact_method_params
      params.require(:party_contact_method).permit(
        :contact_type, :value, :is_primary, :status, :label
      )
    end

    def save_with_primary_demotion!(record)
      active_primary = record.status == "active" && record.is_primary?
      success = false
      PartyContactMethod.transaction do
        if active_primary
          scope = @party.party_contact_methods
            .where(contact_type: record.contact_type, status: "active", is_primary: true)
          scope = scope.where.not(id: record.id) if record.persisted?
          scope.update_all(is_primary: false)
        end
        success = record.save
        raise ActiveRecord::Rollback unless success
      end
      success
    end
  end
end

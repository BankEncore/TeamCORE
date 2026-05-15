# frozen_string_literal: true

module Admin
  class PartyRelationshipsController < BaseController
    before_action :require_current_agency!
    before_action :set_source_party
    before_action :set_party_relationship, only: %i[edit update promote]

    def index
      @party_relationships = scoped(PartyRelationship).where(
        source_party_id: @source_party.id,
        relationship_type: "subcontractor"
      ).includes(:target_party).order(:id)
    end

    def new
      @party_relationship = PartyRelationship.new(
        agency: current_agency,
        source_party: @source_party,
        relationship_type: "subcontractor",
        status: "active"
      )
      load_target_collection
    end

    def create
      @party_relationship =
        PartyRelationship.new(relationship_params.merge(
          agency: current_agency,
          source_party: @source_party,
          relationship_type: "subcontractor"
        ))
      load_target_collection
      if @party_relationship.save
        redirect_to admin_party_party_relationships_path(@source_party), notice: "Subcontractor relationship created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_target_collection
    end

    def update
      load_target_collection
      if @party_relationship.update(relationship_params)
        redirect_to admin_party_party_relationships_path(@source_party), notice: "Subcontractor relationship updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def promote
      result = Subcontractors::PromoteRelatedParty.call(
        party_relationship: @party_relationship,
        agency: current_agency
      )
      if result.success?
        redirect_to admin_engagement_path(result.engagement), result.flash_key => result.flash
      else
        redirect_to admin_party_party_relationships_path(@source_party), result.flash_key => result.flash
      end
    end

    private

    def set_source_party
      @source_party = scoped(Party).find(params[:party_id])
    end

    def set_party_relationship
      @party_relationship =
        scoped(PartyRelationship).where(
          source_party_id: @source_party.id,
          relationship_type: "subcontractor"
        ).find(params[:id])
    end

    def relationship_params
      params.require(:party_relationship).permit(
        :target_party_id, :status, :effective_start_date, :effective_end_date, :notes
      )
    end

    def load_target_collection
      @target_parties =
        Party
          .where(agency_id: current_agency.id)
          .where.not(id: @source_party.id)
          .order(:display_name, :id)
    end
  end
end

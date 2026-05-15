# frozen_string_literal: true

module Admin
  class EngagementsController < Admin::BaseController
    RELATIONSHIP_TYPES_BY_PARTY = {
      "person" => %w[employee individual_contractor subcontractor],
      "organization" => %w[contractor_organization subcontractor]
    }.freeze

    before_action :require_current_agency!
    before_action :set_engagement, only: %i[show edit update]

    def index
      @engagements = Engagement.where(agency_id: current_agency.id).includes(team_member: :party).order(:id)
    end

    def show
      @placement_rows = @engagement.engagement_organization_placements.order(:effective_start_on)
      @supervision_rows = @engagement.engagement_supervision_assignments.order(:effective_start_on)
      if @engagement.relationship_type == "subcontractor"
        @subcontractor_context_rels =
          PartyRelationship
            .where(
              agency_id: current_agency.id,
              target_party_id: @engagement.team_member.party_id,
              relationship_type: "subcontractor"
            )
            .includes(:source_party)
            .order(effective_start_date: :desc, id: :desc)
      end

      @document_readiness = Documents::ReadinessEvaluator.new(engagement: @engagement).call
    end

    def new
      @engagement = Engagement.new(agency: current_agency)
      @relationship_types = Engagement::RELATIONSHIP_TYPES
      load_form_collections
    end

    def create
      @engagement = Engagement.new(base_engagement_attrs.merge(agency: current_agency))
      validate_relationship_type!

      if @engagement.errors.empty? && @engagement.save
        redirect_to admin_engagement_path(@engagement), notice: "Engagement created."
      else
        party = @engagement.team_member&.party
        @relationship_types = party.present? ? relationship_types_for(party) : Engagement::RELATIONSHIP_TYPES
        load_form_collections
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_collections
      @status_options = status_options_for(@engagement)
      @relationship_types = relationship_types_for(@engagement.team_member.party)
    end

    def update
      @engagement.assign_attributes(update_engagement_attrs)
      validate_relationship_type!

      if @engagement.errors.empty? && @engagement.save
        redirect_to admin_engagement_path(@engagement), notice: "Engagement updated."
      else
        load_form_collections
        @status_options = status_options_for(@engagement)
        @relationship_types = relationship_types_for(@engagement.team_member.party)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_engagement
      @engagement = Engagement.where(agency_id: current_agency.id).find(params[:id])
    end

    def base_engagement_attrs
      params.require(:engagement).permit(
        :team_member_id, :relationship_type, :title, :notes,
        :start_on, :end_on, :expected_end_on, :renewal_on
      )
    end

    def update_engagement_attrs
      params.require(:engagement).permit(
        :status, :relationship_type, :title, :notes,
        :start_on, :end_on, :expected_end_on, :renewal_on
      )
    end

    def load_form_collections
      @team_members =
        TeamMember.where(agency_id: current_agency.id).includes(:party).order(:id)
    end

    def relationship_types_for(party)
      return Engagement::RELATIONSHIP_TYPES if party.blank?

      RELATIONSHIP_TYPES_BY_PARTY[party.party_type] || []
    end

    def validate_relationship_type!
      party = @engagement.team_member&.party
      allowed = relationship_types_for(party)
      return if allowed.include?(@engagement.relationship_type)

      @engagement.errors.add(:relationship_type, "is not valid for this party type")
    end

    def status_options_for(engagement)
      return Engagement::STATUSES if engagement.new_record?

      cur = engagement.status
      nxt = Engagement::ALLOWED_STATUS_TRANSITIONS[cur] || []
      ([ cur ] + nxt).uniq
    end
  end
end

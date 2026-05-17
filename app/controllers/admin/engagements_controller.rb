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
      if params[:status].present? && Engagement::STATUSES.include?(params[:status])
        @engagements = @engagements.where(status: params[:status])
      end
      if params[:relationship_type].present? && Engagement::RELATIONSHIP_TYPES.include?(params[:relationship_type])
        @engagements = @engagements.where(relationship_type: params[:relationship_type])
      end
      if params[:team_member_id].to_s.match?(/\A\d+\z/)
        @engagements = @engagements.where(team_member_id: params[:team_member_id].to_i)
      end
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
      type_ids =
        (
          @document_readiness.requirements.map(&:document_type_id) +
          @document_readiness.alerts.map(&:document_type_id)
        ).uniq
      @document_types_by_id = DocumentType.where(id: type_ids).index_by(&:id)
      @contractor_classification_support =
        if @engagement.contractor_class?
          Admin::ContractorClassificationSupportPresenter.new(
            engagement: @engagement,
            readiness: @document_readiness,
            document_types_by_id: @document_types_by_id
          )
        end

      @workforce_financial_assignment = CompensationPlanAssignment.current_for_engagement(@engagement)
      @workforce_financial_draw_balance = @engagement.commission_draw_balance if @engagement.allows_employee_commission_draw?
      @workforce_financial_open_charges =
        if @engagement.allows_contractor_charges_and_settlement?
          @engagement.contractor_charges.where(status: %w[open draft]).order(:id).limit(20)
        end
      @setup_checklist =
        Admin::EngagementSetupChecklistPresenter.new(
          engagement: @engagement,
          document_readiness: @document_readiness,
          placement_rows: @placement_rows,
          supervision_rows: @supervision_rows,
          workforce_financial_assignment: @workforce_financial_assignment
        )
    end

    def new
      @engagement = Engagement.new(agency: current_agency)
      if params[:team_member_id].present?
        tm = TeamMember.where(agency_id: current_agency.id).find_by(id: params[:team_member_id])
        @engagement.team_member = tm if tm
      end
      @relationship_types = relationship_types_for(@engagement.team_member&.party)
      load_form_collections
    end

    def create
      @engagement = Engagement.new(base_engagement_attrs.merge(agency: current_agency))
      validate_relationship_type!

      if @engagement.errors.empty? && @engagement.save
        redirect_after_admin_save admin_engagement_path(@engagement), notice: "Engagement created."
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
        redirect_after_admin_save admin_engagement_path(@engagement), notice: "Engagement updated."
      else
        load_form_collections
        @status_options = status_options_for(@engagement)
        @relationship_types = relationship_types_for(@engagement.team_member.party)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_engagement
      @engagement =
        Engagement
          .where(agency_id: current_agency.id)
          .includes(
            :engagement_organization_placements,
            :engagement_supervision_assignments,
            :contractor_charges,
            :contractor_settlement_lines,
            team_member: { party: %i[person_profile organization_profile] }
          )
          .find(params[:id])
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

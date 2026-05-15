# frozen_string_literal: true

module Admin
  class EngagementSupervisionsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_engagement
    before_action :set_assignment, only: %i[show edit update]

    def index
      @assignments = @engagement.engagement_supervision_assignments.order(:effective_start_on)
    end

    def show
    end

    def new
      @assignment = EngagementSupervisionAssignment.new(
        engagement: @engagement,
        relationship_type: "primary_reports_to"
      )
      @supervisor_engagements = supervisor_candidate_engagements
    end

    def create
      @assignment = EngagementSupervisionAssignment.new(assignment_params.merge(engagement: @engagement))
      if @assignment.save
        redirect_to admin_engagement_supervision_assignment_path(@engagement, @assignment), notice: "Supervision saved."
      else
        @supervisor_engagements = supervisor_candidate_engagements
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @supervisor_engagements = supervisor_candidate_engagements
    end

    def update
      if @assignment.update(assignment_params)
        redirect_to admin_engagement_supervision_assignment_path(@engagement, @assignment), notice: "Supervision updated."
      else
        @supervisor_engagements = supervisor_candidate_engagements
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_engagement
      @engagement = Engagement.where(agency_id: current_agency.id).find(params[:engagement_id])
    end

    def set_assignment
      @assignment = EngagementSupervisionAssignment.where(engagement_id: @engagement.id, agency_id: current_agency.id)
        .find(params[:id])
    end

    def supervisor_candidate_engagements
      Engagement.where(agency_id: current_agency.id, relationship_type: "employee", status: "active")
        .where.not(id: @engagement.id)
        .includes(:team_member)
        .order(:id)
    end

    def assignment_params
      params.require(:engagement_supervision_assignment).permit(
        :supervisor_engagement_id, :relationship_type,
        :effective_start_on, :effective_end_on, :notes
      )
    end
  end
end

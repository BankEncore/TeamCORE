# frozen_string_literal: true

module Admin
  class EngagementPlacementsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_engagement
    before_action :set_placement, only: %i[show edit update]

    def index
      @placements = @engagement.engagement_organization_placements.order(:effective_start_on)
    end

    def show
    end

    def new
      @placement = EngagementOrganizationPlacement.new(engagement: @engagement)
      load_org_rows
    end

    def create
      @placement = EngagementOrganizationPlacement.new(placement_params.merge(engagement: @engagement))
      if @placement.save
        redirect_after_admin_save admin_engagement_placement_path(@engagement, @placement), notice: "Placement saved."
      else
        load_org_rows
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_org_rows
    end

    def update
      if @placement.update(placement_params)
        redirect_after_admin_save admin_engagement_placement_path(@engagement, @placement), notice: "Placement updated."
      else
        load_org_rows
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_engagement
      @engagement = Engagement.where(agency_id: current_agency.id).find(params[:engagement_id])
    end

    def set_placement
      @placement = EngagementOrganizationPlacement.where(engagement_id: @engagement.id, agency_id: current_agency.id)
        .find(params[:id])
    end

    def load_org_rows
      aid = current_agency.id
      @departments = Department.where(agency_id: aid, status: "active").order(:code)
      @locations = Location.where(agency_id: aid, status: "active").order(:code)
      @teams = Team.where(agency_id: aid, status: "active").order(:code)
    end

    def placement_params
      params.require(:engagement_organization_placement).permit(
        :department_id, :location_id, :team_id,
        :effective_start_on, :effective_end_on, :notes
      )
    end
  end
end

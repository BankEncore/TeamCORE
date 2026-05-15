# frozen_string_literal: true

module Admin
  class TeamsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_team, only: %i[show edit update]

    def index
      @teams = Team.where(agency_id: current_agency.id).order(:code)
    end

    def show
    end

    def new
      @team = Team.new(agency: current_agency, status: "active")
      load_org_collections
    end

    def create
      @team = Team.new(team_params.merge(agency: current_agency))
      if @team.save
        redirect_to admin_team_path(@team), notice: "Team created."
      else
        load_org_collections
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_org_collections
    end

    def update
      if @team.update(team_params)
        redirect_to admin_team_path(@team), notice: "Team updated."
      else
        load_org_collections
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_team
      @team = Team.where(agency_id: current_agency.id).find(params[:id])
    end

    def load_org_collections
      @departments = Department.where(agency_id: current_agency.id).order(:code)
      @locations = Location.where(agency_id: current_agency.id).order(:code)
    end

    def team_params
      params.require(:team).permit(:name, :code, :description, :status, :department_id, :location_id)
    end
  end
end

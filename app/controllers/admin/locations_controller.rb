# frozen_string_literal: true

module Admin
  class LocationsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_location, only: %i[show edit update]

    def index
      @locations = Location.where(agency_id: current_agency.id).order(:code)
    end

    def show
    end

    def new
      @location = Location.new(agency: current_agency, status: "active")
    end

    def create
      @location = Location.new(location_params.merge(agency: current_agency))
      if @location.save
        redirect_to admin_location_path(@location), notice: "Location created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @location.update(location_params)
        redirect_to admin_location_path(@location), notice: "Location updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_location
      @location = Location.where(agency_id: current_agency.id).find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :code, :location_type, :timezone, :description, :status)
    end
  end
end

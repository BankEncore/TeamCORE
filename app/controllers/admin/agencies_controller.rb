# frozen_string_literal: true

module Admin
  class AgenciesController < Admin::BaseController
    before_action :set_agency_for_member_action, only: %i[show edit update]

    def index
      @agencies = current_user.agencies.order(:name)
    end

    def show
    end

    def edit
    end

    def update
      if @agency.update(agency_params)
        redirect_to admin_agency_path(@agency), notice: "Agency updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_agency_for_member_action
      @agency = current_user.agencies.find(params[:id])
    end

    def agency_params
      params.require(:agency).permit(:name, :code, :status)
    end
  end
end

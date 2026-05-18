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
      @agency.build_agency_payroll_configuration unless @agency.agency_payroll_configuration
    end

    def update
      @agency.build_agency_payroll_configuration unless @agency.agency_payroll_configuration
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
      params.require(:agency).permit(
        :name,
        :code,
        :status,
        agency_payroll_configuration_attributes: %i[
          id
          payroll_frequency
          workweek_starts_on
          payroll_timezone
          weekly_overtime_threshold_hours
          pay_schedule_anchor_on
        ]
      )
    end
  end
end

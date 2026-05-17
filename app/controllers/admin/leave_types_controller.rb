# frozen_string_literal: true

module Admin
  class LeaveTypesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_leave_type, only: %i[show edit update destroy]

    def index
      @leave_types = current_agency.leave_types.order(:code)
    end

    def show
      redirect_to edit_admin_leave_type_path(@leave_type)
    end

    def new
      @leave_type = current_agency.leave_types.build(active: true, paid: false, balance_tracked: false)
    end

    def create
      @leave_type = current_agency.leave_types.build(leave_type_params)
      if @leave_type.save
        redirect_to admin_leave_types_path, notice: "Leave type created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @leave_type.update(leave_type_params)
        redirect_to admin_leave_types_path, notice: "Leave type updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @leave_type.leave_requests.exists?
        redirect_to admin_leave_types_path, alert: "Cannot delete leave type that has requests."
      else
        @leave_type.destroy!
        redirect_to admin_leave_types_path, notice: "Leave type removed."
      end
    end

    private

    def set_leave_type
      @leave_type = current_agency.leave_types.find(params[:id])
    end

    def leave_type_params
      params.require(:leave_type).permit(
        :code, :name, :paid, :balance_tracked, :active, :description, :payroll_earning_code_id
      )
    end
  end
end

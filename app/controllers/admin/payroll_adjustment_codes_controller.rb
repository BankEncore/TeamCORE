# frozen_string_literal: true

module Admin
  class PayrollAdjustmentCodesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :require_payroll_input_access!
    before_action :set_code, only: %i[edit update destroy]

    def index
      @codes = scoped(PayrollAdjustmentCode).order(:code)
    end

    def new
      @code = scoped(PayrollAdjustmentCode).build
    end

    def create
      @code = scoped(PayrollAdjustmentCode).build(code_params)
      if @code.save
        redirect_to admin_payroll_adjustment_codes_path, notice: "Adjustment code created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @code.update(code_params)
        redirect_to admin_payroll_adjustment_codes_path, notice: "Adjustment code updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @code.destroy!
      redirect_to admin_payroll_adjustment_codes_path, notice: "Adjustment code removed."
    end

    private

    def require_payroll_input_access!
      return if Payroll::Access.can_manage_payroll_input?(user: current_user, agency: current_agency)

      redirect_to admin_root_path, alert: "Not permitted."
    end

    def set_code
      @code = scoped(PayrollAdjustmentCode).find(params[:id])
    end

    def code_params
      params.require(:payroll_adjustment_code).permit(:code, :name, :direction, :active)
    end
  end
end

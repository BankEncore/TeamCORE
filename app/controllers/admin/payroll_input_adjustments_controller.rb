# frozen_string_literal: true

module Admin
  class PayrollInputAdjustmentsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :require_payroll_input_access!
    before_action :set_pay_period_and_batch
    before_action :ensure_batch_draft!, only: %i[new create destroy]

    def new
      @adjustment = @batch.payroll_input_adjustments.build
      @codes = scoped(PayrollAdjustmentCode).active_codes.order(:code)
      @engagements = Engagement.where(agency_id: current_agency.id, relationship_type: "employee").order(:id)
    end

    def create
      @adjustment = @batch.payroll_input_adjustments.build(adjustment_params.reverse_merge(currency: "USD"))
      if @adjustment.save
        Payroll::PayrollInputAssemblyService.call(batch: @batch, actor: current_user)
        redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), notice: "Adjustment added."
      else
        @codes = scoped(PayrollAdjustmentCode).active_codes.order(:code)
        @engagements = Engagement.where(agency_id: current_agency.id, relationship_type: "employee").order(:id)
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      adj = @batch.payroll_input_adjustments.find(params[:id])
      adj.destroy!
      Payroll::PayrollInputAssemblyService.call(batch: @batch, actor: current_user)
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), notice: "Adjustment removed."
    end

    private

    def require_payroll_input_access!
      return if Payroll::Access.can_manage_payroll_input?(user: current_user, agency: current_agency)

      redirect_to admin_root_path, alert: "Not permitted."
    end

    def ensure_batch_draft!
      return if @batch.draft?

      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch),
        alert: "Adjustments can only be edited on draft batches."
    end

    def set_pay_period_and_batch
      @pay_period = scoped(PayPeriod).find(params[:pay_period_id])
      @batch = @pay_period.payroll_input_batches.find(params[:payroll_input_batch_id])
    end

    def adjustment_params
      params.require(:payroll_input_adjustment).permit(
        :payroll_adjustment_code_id,
        :engagement_id,
        :hours,
        :amount,
        :currency,
        :notes
      )
    end
  end
end

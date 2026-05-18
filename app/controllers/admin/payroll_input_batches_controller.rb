# frozen_string_literal: true

module Admin
  class PayrollInputBatchesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :require_payroll_input_access!
    before_action :set_pay_period
    before_action :set_batch, only: %i[show recalculate finalize reverse complete_final_export]

    def index
      @batches = @pay_period.payroll_input_batches.order(reference_sequence: :desc)
    end

    def show
      @rows = @batch.payroll_input_rows.includes(:engagement).order(:id)
      @adjustments = @batch.payroll_input_adjustments.includes(:payroll_adjustment_code, :engagement)
    end

    def create
      batch = Payroll::PayrollInputBatchEnsureDraftService.call(pay_period: @pay_period, actor: current_user)
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, batch), notice: "Draft payroll input batch ready."
    rescue Payroll::PayrollInputBatchEnsureDraftService::Error => e
      redirect_to admin_pay_period_path(@pay_period), alert: e.message
    end

    def recalculate
      Payroll::PayrollInputAssemblyService.call(batch: @batch, actor: current_user)
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), notice: "Batch recalculated."
    rescue Payroll::PayrollInputAssemblyService::Error => e
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), alert: e.message
    end

    def finalize
      Payroll::FinalizePayrollInputBatchService.call(batch: @batch, actor: current_user)
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), notice: "Batch finalized."
    rescue Payroll::FinalizePayrollInputBatchService::Error => e
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), alert: e.message
    end

    def reverse
      successor = Payroll::ReversePayrollInputBatchService.call(
        batch: @batch,
        actor: current_user,
        reason: params.require(:reason)
      )
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, successor),
        notice: "Batch reversed; new draft created."
    rescue Payroll::ReversePayrollInputBatchService::Error, ActionController::ParameterMissing => e
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), alert: e.message
    end

    def complete_final_export
      Payroll::MarkPayrollInputBatchExportedService.call(
        batch: @batch,
        actor: current_user,
        file_format: params.fetch(:file_format, "csv"),
        override_validation: ActiveModel::Type::Boolean.new.cast(params[:override_validation]),
        override_reason: params[:override_reason].presence
      )
      redirect_to admin_pay_period_path(@pay_period), notice: "Final export recorded and pay period closed."
    rescue Payroll::MarkPayrollInputBatchExportedService::Error => e
      redirect_to admin_pay_period_payroll_input_batch_path(@pay_period, @batch), alert: e.message
    end

    private

    def require_payroll_input_access!
      return if Payroll::Access.can_manage_payroll_input?(user: current_user, agency: current_agency)

      redirect_to admin_root_path, alert: "Not permitted."
    end

    def set_pay_period
      @pay_period = scoped(PayPeriod).find(params[:pay_period_id])
    end

    def set_batch
      @batch = @pay_period.payroll_input_batches.find(params[:id])
    end
  end
end

# frozen_string_literal: true

module Admin
  class PayPeriodsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_pay_period, only: %i[show edit update close]

    def index
      @pay_periods = scoped(PayPeriod).order(start_on: :desc)
    end

    def show
      @payroll_exports = Payroll::PayPeriodQueries.export_history(@pay_period)
    end

    def edit
    end

    def update
      if @pay_period.update(pay_period_params)
        redirect_to admin_pay_period_path(@pay_period), notice: "Pay period updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def generate
      months_ahead = params.fetch(:horizon_months_ahead, 24).to_i.clamp(1, 120)
      months_back = params.fetch(:horizon_months_back, 36).to_i.clamp(0, 120)
      result = Payroll::PayPeriodGenerationService.call(
        agency: current_agency,
        actor: current_user,
        horizon_months_ahead: months_ahead,
        horizon_months_back: months_back
      )
      redirect_to admin_pay_periods_path,
        notice: "Pay periods ensured (#{result[:created]} new records this run)."
    rescue Payroll::PayPeriodGenerationService::Error => e
      redirect_to admin_pay_periods_path, alert: e.message
    end

    def close
      override = ActiveModel::Type::Boolean.new.cast(params[:override_validation])
      Payroll::PayPeriodClosureService.call(
        pay_period: @pay_period,
        actor: current_user,
        override_validation: override,
        override_reason: params[:override_reason].presence,
        source: PayPeriodClosureEvent::SOURCES.fetch(:admin_manual)
      )
      redirect_to admin_pay_period_path(@pay_period), notice: "Pay period closed."
    rescue Payroll::PayPeriodClosureService::Error => e
      redirect_to admin_pay_period_path(@pay_period), alert: e.message
    end

    private

    def set_pay_period
      @pay_period = scoped(PayPeriod).find(params[:id])
    end

    def pay_period_params
      params.require(:pay_period).permit(:label)
    end
  end
end

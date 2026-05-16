# frozen_string_literal: true

module Admin
  class PayPeriodsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_pay_period, only: %i[show edit update]

    def index
      @pay_periods = scoped(PayPeriod).order(start_on: :desc)
    end

    def show
    end

    def new
      @pay_period = current_agency.pay_periods.new
    end

    def create
      @pay_period = current_agency.pay_periods.new(pay_period_params)
      if @pay_period.save
        redirect_to admin_pay_period_path(@pay_period), notice: "Pay period created."
      else
        render :new, status: :unprocessable_entity
      end
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

    private

    def set_pay_period
      @pay_period = scoped(PayPeriod).find(params[:id])
    end

    def pay_period_params
      params.require(:pay_period).permit(:label, :start_on, :end_on)
    end
  end
end

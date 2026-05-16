# frozen_string_literal: true

module Admin
  class CompensationPlansController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_plan, only: %i[show edit update]

    def index
      @compensation_plans = scoped(CompensationPlan).order(:name)
    end

    def show
    end

    def new
      @compensation_plan = current_agency.compensation_plans.new
    end

    def create
      @compensation_plan = current_agency.compensation_plans.new(plan_params)
      if @compensation_plan.save
        redirect_to admin_compensation_plan_path(@compensation_plan), notice: "Plan created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @compensation_plan.update(plan_params)
        redirect_to admin_compensation_plan_path(@compensation_plan), notice: "Plan updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @compensation_plan = scoped(CompensationPlan).find(params[:id])
    end

    def plan_params
      params.require(:compensation_plan).permit(
        :name, :plan_type, :status,
        :salary_annual_money, :hourly_rate_money, :default_commission_rate_percent,
        :minimum_commission_basis, :minimum_commission_amount_money, :recovery_rule
      )
    end
  end
end

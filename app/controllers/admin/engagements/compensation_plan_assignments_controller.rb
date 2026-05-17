# frozen_string_literal: true

module Admin
  module Engagements
    class CompensationPlanAssignmentsController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement

      def index
        @assignments = @engagement.compensation_plan_assignments.order(effective_start_on: :desc)
      end

      def new
        @assignment = @engagement.compensation_plan_assignments.build(agency_id: current_agency.id)
        @plans = scoped(CompensationPlan).active_catalog.order(:name)
      end

      def create
        @assignment = @engagement.compensation_plan_assignments.build(assignment_params.merge(agency_id: current_agency.id))
        if @assignment.save
          redirect_after_admin_save admin_engagement_compensation_plan_assignments_path(@engagement), notice: "Assignment created."
        else
          @plans = scoped(CompensationPlan).active_catalog.order(:name)
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @assignment = @engagement.compensation_plan_assignments.find(params[:id])
        @plans = scoped(CompensationPlan).active_catalog.order(:name)
      end

      def update
        @assignment = @engagement.compensation_plan_assignments.find(params[:id])
        if @assignment.update(assignment_params)
          redirect_after_admin_save admin_engagement_compensation_plan_assignments_path(@engagement), notice: "Assignment updated."
        else
          @plans = scoped(CompensationPlan).active_catalog.order(:name)
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @assignment = @engagement.compensation_plan_assignments.find(params[:id])
        @assignment.destroy!
        redirect_after_admin_save admin_engagement_compensation_plan_assignments_path(@engagement), notice: "Removed."
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end

      def assignment_params
        params.require(:compensation_plan_assignment).permit(
          :compensation_plan_id, :effective_start_on, :effective_end_on,
          :snapshot_plan_name, :snapshot_plan_type, :snapshot_commission_rate_percent,
          :snapshot_minimum_basis, :snapshot_minimum_amount_money, :snapshot_recovery_rule,
          :snapshot_salary_annual_money, :snapshot_hourly_rate_money
        )
      end
    end
  end
end

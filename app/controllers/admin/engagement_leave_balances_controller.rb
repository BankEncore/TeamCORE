# frozen_string_literal: true

module Admin
  class EngagementLeaveBalancesController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_engagement

    def index
      @tracked_types = current_agency.leave_types.active.where(balance_tracked: true).order(:code)
      @balances_by_type_id =
        @engagement
          .leave_balances
          .where(leave_type_id: @tracked_types.select(:id))
          .index_by(&:leave_type_id)
      @adjustments =
        LeaveBalanceAdjustment
          .joins(:leave_balance)
          .where(leave_balances: { engagement_id: @engagement.id })
          .includes(:adjusted_by)
          .order(adjusted_at: :desc, id: :desc)
          .limit(50)
    end

    def create
      lt = current_agency.leave_types.active.where(balance_tracked: true).find(params[:leave_type_id])
      bal = LeaveBalance.find_or_create_by!(engagement: @engagement, leave_type: lt)
      Leave::LeaveBalanceAdjustmentService.call(
        leave_balance: bal,
        adjustment_hours: params[:adjustment_hours],
        reason: params[:reason],
        actor: current_user
      )
      redirect_to admin_engagement_leave_balances_path(@engagement), notice: "Balance adjusted."
    rescue Leave::LeaveBalanceAdjustmentService::Error, ActiveRecord::RecordInvalid => e
      redirect_to admin_engagement_leave_balances_path(@engagement), alert: e.message
    end

    private

    def set_engagement
      @engagement = Engagement.where(agency_id: current_agency.id).find(params[:engagement_id])
    end
  end
end

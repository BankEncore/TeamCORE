# frozen_string_literal: true

module Admin
  class LeaveRequestsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_leave_request, only: %i[show edit update submit approve reject cancel reopen]

    def index
      scope =
        LeaveRequest
          .joins(:engagement)
          .where(engagements: { agency_id: current_agency.id }, status: "submitted")
          .includes(:leave_type, engagement: { team_member: :party })
          .order(submitted_at: :desc, id: :desc)

      @queue_rows =
        scope.map do |req|
          age_days =
            if req.submitted_at.present?
              (Date.current - req.submitted_at.to_date).to_i
            end
          { req:, days_pending: age_days }
        end
    end

    def show
      @visibility = Payroll::LeavePayrollVisibilityPresenter.for_leave_request(@leave_request)
      @approval_events = @leave_request.leave_request_approval_events.recent_first.limit(50)
    end

    def new
      @leave_request =
        LeaveRequest.new(
          engagement_id: params[:engagement_id],
          status: "draft"
        )
      build_day_rows(@leave_request)
    end

    def create
      @leave_request = LeaveRequest.new(leave_request_params.merge(status: "draft"))
      unless engagement_in_agency?(@leave_request.engagement_id)
        @leave_request.errors.add(:engagement_id, "must belong to the current agency.")
        build_day_rows(@leave_request)
        return render :new, status: :unprocessable_entity
      end

      if @leave_request.save
        redirect_to admin_leave_request_path(@leave_request), notice: "Leave request saved as draft."
      else
        build_day_rows(@leave_request)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      unless @leave_request.status == "draft"
        redirect_to admin_leave_request_path(@leave_request), alert: "Only draft requests can be edited."
        return
      end

      build_day_rows(@leave_request) if @leave_request.leave_request_days.empty?
    end

    def update
      unless @leave_request.status == "draft"
        redirect_to admin_leave_request_path(@leave_request), alert: "Only draft requests can be edited."
        return
      end

      @leave_request.assign_attributes(leave_request_params)
      unless engagement_in_agency?(@leave_request.engagement_id)
        @leave_request.errors.add(:engagement_id, "must belong to the current agency.")
        build_day_rows(@leave_request)
        return render :edit, status: :unprocessable_entity
      end

      if @leave_request.save
        redirect_to admin_leave_request_path(@leave_request), notice: "Leave request updated."
      else
        build_day_rows(@leave_request)
        render :edit, status: :unprocessable_entity
      end
    end

    def submit
      Leave::LeaveRequestService.new(leave_request: @leave_request, actor: current_user).submit!
      redirect_to admin_leave_request_path(@leave_request), notice: "Leave request submitted."
    rescue Leave::LeaveRequestService::Error => e
      redirect_to admin_leave_request_path(@leave_request), alert: e.message
    end

    def approve
      Leave::LeaveRequestService.new(leave_request: @leave_request, actor: current_user).approve!(review_notes: params[:review_notes])
      redirect_to admin_leave_request_path(@leave_request), notice: "Leave request approved."
    rescue Leave::LeaveRequestService::Error => e
      redirect_to admin_leave_request_path(@leave_request), alert: e.message
    end

    def reject
      Leave::LeaveRequestService.new(leave_request: @leave_request, actor: current_user).reject!(review_notes: params[:review_notes])
      redirect_to admin_leave_requests_path, notice: "Leave request rejected."
    rescue Leave::LeaveRequestService::Error => e
      redirect_to admin_leave_request_path(@leave_request), alert: e.message
    end

    def cancel
      Leave::LeaveRequestService.new(leave_request: @leave_request, actor: current_user).cancel!(reason: params[:reason])
      redirect_to admin_leave_request_path(@leave_request), notice: "Leave request cancelled."
    rescue Leave::LeaveRequestService::Error => e
      redirect_to admin_leave_request_path(@leave_request), alert: e.message
    end

    def reopen
      Leave::LeaveRequestService.new(leave_request: @leave_request, actor: current_user).reopen_to_draft!(reason: params[:reason])
      redirect_to admin_leave_request_path(@leave_request), notice: "Leave request reopened to draft."
    rescue Leave::LeaveRequestService::Error => e
      redirect_to admin_leave_request_path(@leave_request), alert: e.message
    end

    private

    def build_day_rows(req)
      while req.leave_request_days.size < 5
        req.leave_request_days.build(hours: 0)
      end
    end

    def engagement_in_agency?(engagement_id)
      return false if engagement_id.blank?

      Engagement.exists?(id: engagement_id, agency_id: current_agency.id)
    end

    def set_leave_request
      @leave_request =
        LeaveRequest
          .joins(:engagement)
          .where(engagements: { agency_id: current_agency.id })
          .find(params[:id])
    end

    def leave_request_params
      params.require(:leave_request).permit(
        :engagement_id,
        :leave_type_id,
        :notes,
        leave_request_days_attributes: %i[id leave_date hours _destroy]
      )
    end
  end
end

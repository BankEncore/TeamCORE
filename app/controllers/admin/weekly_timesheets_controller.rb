# frozen_string_literal: true

module Admin
  class WeeklyTimesheetsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_weekly_timesheet, only: %i[show approve send_back reopen]

    def index
      scope =
        WeeklyTimesheet
          .joins(:engagement)
          .where(engagements: { agency_id: current_agency.id })
          .where(status: "submitted")
          .includes(engagement: { team_member: :party })
          .order(submitted_at: :desc, id: :desc)

      @queue_rows =
        scope.map do |sheet|
          age_days =
            if sheet.submitted_at.present?
              (Date.current - sheet.submitted_at.to_date).to_i
            end
          { sheet:, days_pending: age_days }
        end
    end

    def show
      @overtime_view = Payroll::TimesheetOvertimePresenter.for_timesheet(@weekly_timesheet)
      @daily_hours =
        DailyWorkedHour
          .where(
            engagement_id: @weekly_timesheet.engagement_id,
            work_date: @weekly_timesheet.week_start_on..@weekly_timesheet.week_end_on
          )
          .order(:work_date)
      @approval_events = @weekly_timesheet.weekly_timesheet_approval_events.recent_first.limit(50)
    end

    def approve
      Payroll::TimesheetApprovalService.new(weekly_timesheet: @weekly_timesheet, actor: current_user).approve!
      redirect_to admin_weekly_timesheet_path(@weekly_timesheet), notice: "Timesheet approved."
    rescue Payroll::TimesheetApprovalService::Error => e
      redirect_to admin_weekly_timesheet_path(@weekly_timesheet), alert: e.message
    end

    def send_back
      Payroll::TimesheetApprovalService.new(weekly_timesheet: @weekly_timesheet, actor: current_user)
        .send_back_to_draft!(
          reason: params[:reason],
          disposition: params[:disposition].presence || "sent_back"
        )
      redirect_to admin_weekly_timesheets_path, notice: "Timesheet returned for correction."
    rescue Payroll::TimesheetApprovalService::Error => e
      redirect_to admin_weekly_timesheet_path(@weekly_timesheet), alert: e.message
    end

    def reopen
      Payroll::TimesheetApprovalService.new(weekly_timesheet: @weekly_timesheet, actor: current_user)
        .reopen_to_draft!(reason: params[:reason])
      redirect_to admin_weekly_timesheets_path, notice: "Timesheet reopened to draft."
    rescue Payroll::TimesheetApprovalService::Error => e
      redirect_to admin_weekly_timesheet_path(@weekly_timesheet), alert: e.message
    end

    private

    def set_weekly_timesheet
      @weekly_timesheet =
        WeeklyTimesheet
          .joins(:engagement)
          .where(engagements: { agency_id: current_agency.id })
          .find(params[:id])
    end
  end
end

# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    def show
      @agency_count = current_user.agencies.count
      return if @agency_count.zero? || current_agency.blank?

      aid = current_agency.id
      @draft_engagements_count = Engagement.where(agency_id: aid, status: "draft").count
      @pending_engagements_count = Engagement.where(agency_id: aid, status: "pending").count
      @submitted_documents_count = DocumentRecord.where(agency_id: aid, status: "submitted").count
      @open_contractor_charges_count =
        ContractorCharge.where(agency_id: aid).where(status: %w[draft open]).count
      today = Date.current
      @past_due_contractor_charges_count =
        ContractorCharge
          .where(agency_id: aid)
          .where(status: %w[draft open])
          .where.not(due_on: nil)
          .where("contractor_charges.due_on < ?", today)
          .count
      @draft_settlement_runs_count = ContractorSettlementRun.where(agency_id: aid, status: "draft").count
      @pending_weekly_timesheets_count =
        WeeklyTimesheet
          .joins(:engagement)
          .where(engagements: { agency_id: aid }, status: "submitted")
          .count
    end
  end
end

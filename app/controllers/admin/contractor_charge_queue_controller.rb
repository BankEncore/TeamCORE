# frozen_string_literal: true

module Admin
  # Agency-wide contractor charges index (filters for dashboard deep links). Per-engagement CRUD stays under engagements.
  class ContractorChargeQueueController < Admin::BaseController
    before_action :require_current_agency!

    def index
      @charges =
        ContractorCharge
          .where(agency_id: current_agency.id)
          .includes(:engagement, engagement: { team_member: :party })
          .order(id: :desc)

      if params[:status].present? && ContractorCharge::STATUSES.include?(params[:status])
        @charges = @charges.where(status: params[:status])
      end

      if params[:past_due] == "1"
        today = Date.current
        @charges = @charges.where.not(due_on: nil).where("contractor_charges.due_on < ?", today)
      end
    end
  end
end

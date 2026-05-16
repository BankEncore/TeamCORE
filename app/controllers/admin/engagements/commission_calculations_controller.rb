# frozen_string_literal: true

module Admin
  module Engagements
    class CommissionCalculationsController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement
      before_action :set_calculation, only: %i[finalize]

      def index
        @calculations = @engagement.commission_calculations.order(id: :desc).limit(100)
      end

      def finalize
        unless @calculation.status == "draft"
          redirect_to admin_engagement_commission_calculations_path(@engagement),
            alert: "Only draft calculations can be finalized (currently #{@calculation.status})."
          return
        end

        @calculation.update!(status: "finalized")
        redirect_to admin_engagement_commission_calculations_path(@engagement),
          notice: "Commission calculation ##{@calculation.id} finalized."
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end

      def set_calculation
        @calculation = @engagement.commission_calculations.find(params[:id])
      end
    end
  end
end

# frozen_string_literal: true

module Admin
  module Engagements
    class CommissionCalculationsController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement

      def index
        @calculations = @engagement.commission_calculations.order(id: :desc).limit(100)
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end
    end
  end
end

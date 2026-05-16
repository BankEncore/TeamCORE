# frozen_string_literal: true

module Admin
  module Engagements
    class ContractorChargeWaiversController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement
      before_action :set_charge

      def new
        @waiver = @charge.contractor_charge_waivers.build(agency_id: current_agency.id, actor: current_user)
      end

      def create
        @waiver = @charge.contractor_charge_waivers.build(waiver_params.merge(agency_id: current_agency.id, actor: current_user))
        if @waiver.save
          redirect_to admin_engagement_contractor_charge_path(@engagement, @charge), notice: "Waiver recorded."
        else
          render :new, status: :unprocessable_entity
        end
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end

      def set_charge
        @charge = @engagement.contractor_charges.find(params[:contractor_charge_id])
      end

      def waiver_params
        params.require(:contractor_charge_waiver).permit(:amount_money, :reason)
      end
    end
  end
end

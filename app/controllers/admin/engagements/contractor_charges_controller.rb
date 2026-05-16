# frozen_string_literal: true

module Admin
  module Engagements
    class ContractorChargesController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement
      before_action :set_charge, only: %i[show edit update]

      def index
        @charges = @engagement.contractor_charges.order(id: :desc)
      end

      def show
      end

      def new
        @charge = @engagement.contractor_charges.build(agency_id: current_agency.id, status: "open")
      end

      def create
        @charge = @engagement.contractor_charges.build(charge_params.merge(agency_id: current_agency.id))
        if @charge.save
          redirect_to admin_engagement_contractor_charges_path(@engagement), notice: "Charge created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @charge.update(charge_params)
          redirect_to admin_engagement_contractor_charge_path(@engagement, @charge), notice: "Updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end

      def set_charge
        @charge = @engagement.contractor_charges.find(params[:id])
      end

      def charge_params
        params.require(:contractor_charge).permit(
          :charge_type, :status, :original_amount_cents, :open_balance_cents, :due_on, :description
        )
      end
    end
  end
end

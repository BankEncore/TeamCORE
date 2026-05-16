# frozen_string_literal: true

module Admin
  module Engagements
    class RevenueInputsController < Admin::BaseController
      before_action :require_current_agency!
      before_action :set_engagement
      before_action :set_revenue_input, only: %i[show edit update calculate_commission]
      before_action :set_commission_lock, only: %i[edit update calculate_commission]

      def index
        @revenue_inputs = @engagement.revenue_inputs.order(id: :desc)
        rev_ids = @revenue_inputs.map(&:id)
        @finalized_revenue_input_ids =
          CommissionCalculation.where(revenue_input_id: rev_ids, status: "finalized").pluck(:revenue_input_id).to_set
      end

      def show
      end

      def new
        @revenue_input = @engagement.revenue_inputs.build(agency_id: current_agency.id, source_type: "manual")
        @pay_periods = scoped(PayPeriod).order(start_on: :desc).limit(50)
      end

      def create
        @revenue_input = @engagement.revenue_inputs.build(revenue_params.merge(agency_id: current_agency.id))
        if @revenue_input.save
          redirect_to admin_engagement_revenue_inputs_path(@engagement), notice: "Revenue input saved."
        else
          @pay_periods = scoped(PayPeriod).order(start_on: :desc).limit(50)
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @pay_periods = scoped(PayPeriod).order(start_on: :desc).limit(50)
      end

      def update
        if @revenue_commission_locked
          redirect_to admin_engagement_revenue_inputs_path(@engagement),
            alert: "This revenue input is locked because its commission calculation is finalized."
          return
        end

        if @revenue_input.update(revenue_params)
          redirect_to admin_engagement_revenue_inputs_path(@engagement), notice: "Updated."
        else
          @pay_periods = scoped(PayPeriod).order(start_on: :desc).limit(50)
          render :edit, status: :unprocessable_entity
        end
      end

      def calculate_commission
        if @revenue_commission_locked
          redirect_to admin_engagement_revenue_inputs_path(@engagement),
            alert: "This revenue input is locked because its commission calculation is finalized."
          return
        end

        Financials::ApplyCommissionAndDraw.call(revenue_input: @revenue_input, actor: current_user)
        redirect_to admin_engagement_commission_calculations_path(@engagement), notice: "Commission calculated."
      rescue ArgumentError => e
        redirect_to admin_engagement_revenue_inputs_path(@engagement), alert: e.message
      end

      def import_csv
        file = params[:csv_file]
        if file.blank?
          redirect_to admin_engagement_revenue_inputs_path(@engagement), alert: "Choose a CSV file."
          return
        end

        require "csv"
        count = 0
        CSV.foreach(file.path, headers: true) do |row|
          h = row.to_h
          next if h["period_start_on"].blank? || h["period_end_on"].blank?
          next if h["commissionable_revenue_cents"].blank? && h["commissionable_revenue"].blank?

          revenue_cents =
            if h["commissionable_revenue_cents"].present?
              h["commissionable_revenue_cents"].to_i
            else
              Teamcore::Money.cents_from_decimal_string(h["commissionable_revenue"])
            end

          gross_cents =
            if h["gross_sales_cents"].present?
              h["gross_sales_cents"].to_i
            elsif h["gross_sales"].present?
              Teamcore::Money.cents_from_decimal_string(h["gross_sales"])
            end

          @engagement.revenue_inputs.create!(
            agency_id: current_agency.id,
            pay_period_id: h["pay_period_id"].presence&.to_i,
            period_start_on: Date.parse(h["period_start_on"]),
            period_end_on: Date.parse(h["period_end_on"]),
            commissionable_revenue_cents: revenue_cents,
            gross_sales_cents: gross_cents,
            source_type: h["source_type"].presence || "imported_csv",
            notes: h["notes"]
          )
          count += 1
        end
        redirect_to admin_engagement_revenue_inputs_path(@engagement), notice: "Imported #{count} row(s)."
      rescue StandardError => e
        redirect_to admin_engagement_revenue_inputs_path(@engagement), alert: "CSV error: #{e.message}"
      end

      private

      def set_engagement
        @engagement = scoped(Engagement).find(params[:engagement_id])
      end

      def set_revenue_input
        @revenue_input = @engagement.revenue_inputs.find(params[:id])
      end

      def revenue_params
        params.require(:revenue_input).permit(
          :pay_period_id, :period_start_on, :period_end_on,
          :commissionable_revenue_money, :gross_sales_money,
          :source_type, :notes
        )
      end

      def set_commission_lock
        @revenue_commission_locked = CommissionCalculation.exists?(
          revenue_input_id: @revenue_input.id,
          status: "finalized"
        )
      end
    end
  end
end

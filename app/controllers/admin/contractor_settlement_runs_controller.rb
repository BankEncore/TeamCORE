# frozen_string_literal: true

module Admin
  class ContractorSettlementRunsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_run, only: %i[show finalize compose_line void mark_paid draft_settlement_export final_settlement_export]

    def index
      @runs = scoped(ContractorSettlementRun).order(id: :desc)
      if params[:status].present? && ContractorSettlementRun::STATUSES.include?(params[:status])
        @runs = @runs.where(status: params[:status])
      end
    end

    def show
      @lines = @run.contractor_settlement_lines.includes(:engagement)
      @events = @run.contractor_settlement_run_events.includes(:actor).order(id: :desc)
      @settlement_exports = @run.contractor_settlement_exports.includes(:exported_by).ordered
      @contractor_engagements = scoped(Engagement).where(
        relationship_type: EngagementFinancialContext::CONTRACTOR_FINANCIAL_TYPES
      ).includes(team_member: :party).order(:id)
    end

    def new
      @run = current_agency.contractor_settlement_runs.new(status: "draft")
    end

    def create
      @run = current_agency.contractor_settlement_runs.new(run_params.merge(status: "draft"))
      if @run.save
        ContractorSettlementRunEvent.create!(
          contractor_settlement_run: @run,
          event_type: "created",
          actor: current_user
        )
        redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement run created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def finalize
      unless @run.status.in?(%w[draft calculated])
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Run cannot be finalized from #{@run.status}."
        return
      end

      ContractorSettlementRun.transaction do
        @run.update!(status: "finalized")
        ContractorSettlementRunEvent.create!(
          contractor_settlement_run: @run,
          event_type: "finalized",
          actor: current_user,
          reason: "Admin finalization"
        )
      end
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement finalized."
    end

    def void
      unless @run.status.in?(%w[draft calculated finalized])
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Run cannot be voided from #{@run.status}."
        return
      end

      reason = params[:reason].to_s.strip.presence || "Voided by admin"
      ContractorSettlementRun.transaction do
        @run.update!(status: "voided")
        ContractorSettlementRunEvent.create!(
          contractor_settlement_run: @run,
          event_type: "voided",
          actor: current_user,
          reason:
        )
      end
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement run voided."
    end

    def mark_paid
      unless @run.status == "finalized"
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Mark paid only applies to finalized runs (#{@run.status})."
        return
      end

      reason = params[:reason].to_s.strip.presence || "Payment recorded"
      ContractorSettlementRun.transaction do
        @run.update!(status: "paid_recorded")
        ContractorSettlementRunEvent.create!(
          contractor_settlement_run: @run,
          event_type: "payment_recorded",
          actor: current_user,
          reason:
        )
      end
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Payment recorded on settlement run."
    end

    def compose_line
      engagement = scoped(Engagement).find(params[:engagement_id])
      Financials::ContractorSettlement::ComposeLine.call(
        run: @run,
        engagement:,
        actor: current_user,
        revenue_input_ids: params[:revenue_input_ids].to_s.split(/[\s,]+/),
        commission_calculation_ids: params[:commission_calculation_ids].to_s.split(/[\s,]+/),
        contractor_charge_ids: params[:contractor_charge_ids].to_s.split(/[\s,]+/),
        manual_positive: parse_money_cents_param(params[:manual_positive_money]),
        manual_negative: parse_money_cents_param(params[:manual_negative_money])
      )
      @run.update!(status: "calculated") if @run.status == "draft"
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement line added."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to admin_contractor_settlement_run_path(@run), alert: e.message
    end

    def draft_settlement_export
      export = Financials::ContractorSettlement::GenerateDraftSettlementExportService.call(
        run: @run,
        actor: current_user,
        file_format: params.fetch(:file_format, "csv")
      )
      redirect_to admin_contractor_settlement_run_path(@run),
        notice: "Draft settlement export ##{export.export_sequence} generated (#{export.file_format.upcase})."
    rescue Financials::ContractorSettlement::GenerateDraftSettlementExportService::Error => e
      redirect_to admin_contractor_settlement_run_path(@run), alert: e.message
    end

    def final_settlement_export
      export = Financials::ContractorSettlement::GenerateFinalSettlementExportService.call(
        run: @run,
        actor: current_user,
        file_format: params.fetch(:file_format, "csv")
      )
      redirect_to admin_contractor_settlement_run_path(@run),
        notice: "Final settlement export ##{export.export_sequence} generated (#{export.file_format.upcase})."
    rescue Financials::ContractorSettlement::GenerateFinalSettlementExportService::Error => e
      redirect_to admin_contractor_settlement_run_path(@run), alert: e.message
    end

    private

    def set_run
      @run = scoped(ContractorSettlementRun).find(params[:id])
    end

    def run_params
      params.require(:contractor_settlement_run).permit(:period_start_on, :period_end_on)
    end

    def parse_money_cents_param(raw)
      s = raw.to_s.strip
      return 0 if s.empty?

      Teamcore::Money.cents_from_decimal_string(s)
    end
  end
end

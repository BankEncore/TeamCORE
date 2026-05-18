# frozen_string_literal: true

module Admin
  class ContractorSettlementRunsController < Admin::BaseController
    before_action :require_current_agency!
    before_action :set_run, only: %i[
      show finalize compose_line void mark_paid draft_settlement_export final_settlement_export
      line_composer preview_settlement_line
    ]

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
      Financials::ContractorSettlement::VoidRunWithReversal.call(
        run: @run,
        actor: current_user,
        reason: params[:reason]
      )
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement run voided. Charge balances restored where applicable."
    rescue Financials::ContractorSettlement::VoidRunWithReversal::Error => e
      redirect_to admin_contractor_settlement_run_path(@run), alert: e.message
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

    def line_composer
      unless @run.status.in?(%w[draft calculated])
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Line composer is only available for draft or calculated runs."
        return
      end

      @engagement = scoped(Engagement).find(params.require(:engagement_id))
      unless @engagement.allows_contractor_charges_and_settlement?
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Selected engagement is not eligible for contractor settlement."
        return
      end

      @preview = build_settlement_preview(explicit: false)
      render :line_composer
    end

    def preview_settlement_line
      unless @run.status.in?(%w[draft calculated])
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Line composer is only available for draft or calculated runs."
        return
      end

      @engagement = scoped(Engagement).find(params.require(:engagement_id))
      unless @engagement.allows_contractor_charges_and_settlement?
        redirect_to admin_contractor_settlement_run_path(@run), alert: "Selected engagement is not eligible for contractor settlement."
        return
      end

      @preview = build_settlement_preview(explicit: true)
      render :line_composer
    rescue ArgumentError, Teamcore::Money::InvalidAmount => e
      redirect_to line_composer_admin_contractor_settlement_run_path(@run, engagement_id: params[:engagement_id]),
        alert: e.message
    end

    def compose_line
      engagement = scoped(Engagement).find(params.require(:engagement_id))
      Financials::ContractorSettlement::ComposeLine.call(
        run: @run,
        engagement:,
        actor: current_user,
        revenue_input_ids: legacy_revenue_input_ids_param,
        commission_calculation_ids: parse_integer_id_list(params[:commission_calculation_ids]),
        contractor_charge_ids: parse_integer_id_list(params[:contractor_charge_ids]),
        manual_positive: parse_money_cents_param(params[:manual_positive_money]),
        manual_negative: parse_money_cents_param(params[:manual_negative_money]),
        charge_deductions_cents_by_id: parse_charge_deductions_param
      )
      @run.update!(status: "calculated") if @run.status == "draft"
      redirect_to admin_contractor_settlement_run_path(@run), notice: "Settlement line added."
    rescue ArgumentError, ActiveRecord::RecordInvalid, Teamcore::Money::InvalidAmount => e
      redirect_to line_composer_admin_contractor_settlement_run_path(@run, engagement_id: params[:engagement_id]),
        alert: e.message
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

    def legacy_revenue_input_ids_param
      raw = params[:revenue_input_ids]
      return [] if raw.blank?

      raw.to_s.split(/[\s,]+/).map(&:to_i).reject(&:zero?)
    end

    def parse_integer_id_list(value)
      case value
      when nil
        []
      when Array
        value.flat_map { |x| x.to_s.split(/[\s,]+/) }.map(&:to_i).reject(&:zero?).uniq
      else
        value.to_s.split(/[\s,]+/).map(&:to_i).reject(&:zero?).uniq
      end
    end

    def parse_charge_deductions_param
      raw = params[:charge_deductions]
      return nil if raw.blank?

      h = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
      out = {}
      h.each do |id, money|
        next if money.blank?

        out[id.to_s] = Teamcore::Money.cents_from_decimal_string(money.to_s)
      end
      out.presence
    end

    def build_settlement_preview(explicit:, engagement: nil)
      engagement ||= @engagement
      include_future_due = params[:include_future_due] == "1"
      mp = parse_money_cents_param(params[:manual_positive_money])
      mn = parse_money_cents_param(params[:manual_negative_money])

      commission_ids = explicit ? parse_integer_id_list(params[:commission_calculation_ids]) : nil
      charge_ids = explicit ? parse_integer_id_list(params[:contractor_charge_ids]) : nil
      charge_map = explicit ? parse_charge_deductions_param : nil

      Financials::ContractorSettlement::PreviewLine.call(
        run: @run,
        engagement:,
        include_future_due: include_future_due,
        manual_positive_cents: mp,
        manual_negative_cents: mn,
        commission_calculation_ids: commission_ids,
        contractor_charge_ids: charge_ids,
        charge_deductions_cents_by_id: charge_map
      )
    end
  end
end

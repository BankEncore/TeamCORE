# frozen_string_literal: true

module Admin
  # Presenter-only engagement setup checklist (GH #111). No persisted state.
  class EngagementSetupChecklistPresenter
    Row = Data.define(:key, :label, :bucket, :detail)

    BUCKETS = %w[complete needs_attention warning not_applicable].freeze

    def initialize(
      engagement:,
      document_readiness:,
      as_of_date: nil,
      placement_rows: nil,
      supervision_rows: nil,
      workforce_financial_assignment: nil
    )
      @engagement = engagement
      @readiness = document_readiness
      @as_of_date = (as_of_date || @readiness&.as_of_date || Date.current)
      @placement_rows = placement_rows || @engagement.engagement_organization_placements.order(:effective_start_on)
      @supervision_rows = supervision_rows || @engagement.engagement_supervision_assignments.order(:effective_start_on)
      @workforce_financial_assignment = workforce_financial_assignment
    end

    def rows
      [
        basic_engagement_row,
        current_placement_row,
        supervision_row,
        document_readiness_row,
        contractor_classification_row,
        compensation_row,
        contractor_charge_row,
        settlement_row
      ].compact
    end

    private

    def basic_engagement_row
      ok = @engagement.title.present? && @engagement.start_on.present?
      Row.new(
        key: :basic_engagement_details,
        label: "Basic engagement details",
        bucket: ok ? "complete" : "needs_attention",
        detail: ok ? nil : "Add a title and start date."
      )
    end

    def current_placement_row
      return not_applicable(:current_placement, "Current placement", "Not on the employee placement path.") unless @engagement.employee_path?

      ok = row_covers_as_of?(@placement_rows, method(:placement_spans_as_of?))
      Row.new(
        key: :current_placement,
        label: "Current placement",
        bucket: ok ? "complete" : "needs_attention",
        detail: ok ? nil : "No department / location / team placement effective on #{@as_of_date}."
      )
    end

    def supervision_row
      return not_applicable(:supervision, "Supervision / oversight", "Not on the employee supervision path.") unless @engagement.employee_path?

      ok = row_covers_as_of?(@supervision_rows, method(:supervision_spans_as_of?))
      Row.new(
        key: :supervision,
        label: "Supervision / oversight",
        bucket: ok ? "complete" : "needs_attention",
        detail: ok ? nil : "No supervision assignment effective on #{@as_of_date}."
      )
    end

    def document_readiness_row
      rs = @readiness.readiness_status
      case rs
      when "ready"
        complete(:document_readiness, "Document readiness", "Evaluator: ready.")
      when "warning"
        Row.new(key: :document_readiness, label: "Document readiness", bucket: "warning", detail: "Evaluator: warning — review requirements.")
      when "not_applicable"
        not_applicable(:document_readiness, "Document readiness", "Not applicable for this engagement.")
      else
        Row.new(key: :document_readiness, label: "Document readiness", bucket: "needs_attention", detail: "Evaluator: not ready — address blocking requirements.")
      end
    end

    def contractor_classification_row
      return not_applicable(:contractor_classification, "Contractor classification support", "Not a contractor-class relationship.") unless @engagement.contractor_class?

      rs = @readiness.readiness_status
      case rs
      when "ready"
        complete(:contractor_classification, "Contractor classification support", "Document posture looks ready.")
      when "warning"
        Row.new(key: :contractor_classification, label: "Contractor classification support", bucket: "warning", detail: "Review contractor document categories.")
      when "not_applicable"
        not_applicable(:contractor_classification, "Contractor classification support", "Evaluator marked N/A.")
      else
        Row.new(key: :contractor_classification, label: "Contractor classification support", bucket: "needs_attention", detail: "Blocking contractor documentation gaps.")
      end
    end

    def compensation_row
      return not_applicable(:compensation, "Compensation setup", "Not on the employee commission path.") unless @engagement.allows_employee_commission_draw?

      ok = @workforce_financial_assignment.present?
      Row.new(
        key: :compensation,
        label: "Compensation setup",
        bucket: ok ? "complete" : "needs_attention",
        detail: ok ? nil : "No effective compensation plan assignment."
      )
    end

    def contractor_charge_row
      return not_applicable(:contractor_charges, "Contractor charge setup", "Charges not used for this relationship type.") unless @engagement.allows_contractor_charges_and_settlement?

      if !@engagement.eligible_for_contractor_class_operational_rails?
        return not_applicable(:contractor_charges, "Contractor charge setup", "Activate the engagement before charge operations.")
      end

      has_charges = @engagement.contractor_charges.exists?
      Row.new(
        key: :contractor_charges,
        label: "Contractor charge setup",
        bucket: has_charges ? "complete" : "needs_attention",
        detail: has_charges ? nil : "No contractor charges recorded yet."
      )
    end

    def settlement_row
      return not_applicable(:settlement, "Settlement readiness", "Settlement not used for this relationship type.") unless @engagement.allows_contractor_charges_and_settlement?

      if !@engagement.eligible_for_contractor_class_operational_rails?
        return not_applicable(:settlement, "Settlement readiness", "Activate the engagement before settlement.")
      end

      open_like = @engagement.contractor_charges.where(status: %w[open draft])
      lines_exist = @engagement.contractor_settlement_lines.exists?

      if open_like.none?
        return complete(:settlement, "Settlement readiness", "No open charges — nothing to settle.")
      end

      if lines_exist
        complete(:settlement, "Settlement readiness", "Settlement lines exist for this engagement.")
      else
        Row.new(
          key: :settlement,
          label: "Settlement readiness",
          bucket: "needs_attention",
          detail: "Open charges exist but no settlement lines yet."
        )
      end
    end

    def complete(key, label, detail)
      Row.new(key:, label:, bucket: "complete", detail:)
    end

    def not_applicable(key, label, detail)
      Row.new(key:, label:, bucket: "not_applicable", detail:)
    end

    def row_covers_as_of?(relation, span_checker)
      relation.any? { |r| span_checker.call(r) }
    end

    def placement_spans_as_of?(p)
      return false if p.effective_start_on.present? && p.effective_start_on > @as_of_date
      return false if p.effective_end_on.present? && p.effective_end_on < @as_of_date

      true
    end

    def supervision_spans_as_of?(s)
      return false if s.effective_start_on.present? && s.effective_start_on > @as_of_date
      return false if s.effective_end_on.present? && s.effective_end_on < @as_of_date

      true
    end
  end
end

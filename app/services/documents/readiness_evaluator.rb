# frozen_string_literal: true

module Documents
  # Single source of truth for engagement document readiness (TC-06 / OD-006 document slice)
  # and derived document alerts (TC-07).
  class ReadinessEvaluator
    REQUIREMENT_OUTCOMES = %w[
      missing pending_verification satisfied rejected expired expiring_soon not_applicable
    ].freeze

    READINESS_STATUSES = %w[ready not_ready warning not_applicable].freeze

    BLOCKING_OUTCOMES = %w[missing rejected expired pending_verification].freeze

    ALERT_OUTCOMES = %w[missing expired expiring_soon rejected pending_verification].freeze

    RequirementEvaluation = Data.define(
      :document_requirement_id,
      :document_type_id,
      :requirement_scope,
      :relationship_type,
      :required,
      :verification_required,
      :requirement_outcome,
      :record_review_status,
      :document_record_id,
      :expires_on
    )

    SEVERITY_RANK = { "blocking" => 0, "warning" => 1, "info" => 2 }.freeze

    ALERT_TYPE_RANK = {
      "missing" => 0,
      "expired" => 1,
      "rejected" => 2,
      "pending_verification" => 3,
      "expiring_soon" => 4
    }.freeze

    def initialize(engagement:, as_of_date: Date.current)
      @engagement = engagement
      @as_of_date = as_of_date
    end

    def call
      raise ArgumentError, "engagement required" if @engagement.blank?

      rows = applicable_requirements.filter_map do |req|
        evaluate_requirement(req)
      end

      alerts = sort_alerts(build_alerts(rows))

      ReadinessResult.new(
        readiness_status: aggregate_readiness(rows),
        as_of_date: @as_of_date,
        engagement_id: @engagement.id,
        requirements: rows,
        alerts: alerts
      )
    end

    private

    def build_alerts(rows)
      req_ids = rows.map(&:document_requirement_id).uniq
      reqs_by_id =
        DocumentRequirement
          .includes(:document_type)
          .where(id: req_ids)
          .index_by(&:id)

      rec_ids = rows.filter_map(&:document_record_id).uniq
      records_by_id =
        DocumentRecord.where(id: rec_ids).index_by(&:id)

      rows.filter_map do |row|
        next unless row.required

        outcome = row.requirement_outcome
        next unless ALERT_OUTCOMES.include?(outcome)

        requirement = reqs_by_id[row.document_requirement_id]
        next unless requirement

        record =
          if row.document_record_id.present?
            records_by_id[row.document_record_id]
          end

        expires_on = row.expires_on
        days_until =
          expires_on.present? ? (expires_on - @as_of_date).to_i : nil

        rejection_reason =
          outcome == "rejected" ? record&.rejection_reason : nil

        severity = outcome == "expiring_soon" ? "warning" : "blocking"

        message = AlertMessageBuilder.build(
          outcome:,
          requirement:,
          as_of_date: @as_of_date,
          rejection_reason:,
          expires_on:,
          days_until_expiration: days_until
        )

        AlertResult.new(
          alert_type: outcome,
          severity:,
          requirement_outcome: outcome,
          record_review_status: row.record_review_status,
          document_requirement_id: requirement.id,
          document_type_id: requirement.document_type_id,
          document_record_id: row.document_record_id,
          engagement_id: @engagement.id,
          team_member_id: @engagement.team_member_id,
          expires_on:,
          days_until_expiration: days_until,
          rejection_reason:,
          message:
        )
      end
    end

    def sort_alerts(alerts)
      type_ids = alerts.map(&:document_type_id).uniq
      codes =
        DocumentType
          .where(id: type_ids)
          .pluck(:id, :code)
          .to_h

      alerts.sort_by do |a|
        expires_jd =
          if a.expires_on.present?
            a.expires_on.jd.to_f
          else
            Float::INFINITY
          end

        [
          SEVERITY_RANK.fetch(a.severity, 99),
          ALERT_TYPE_RANK.fetch(a.alert_type, 99),
          expires_jd,
          codes.fetch(a.document_type_id, "").to_s.downcase,
          a.document_requirement_id,
          a.alert_type.to_s # stable tie-break
        ]
      end
    end

    def applicable_requirements
      DocumentRequirement
        .includes(:document_type)
        .where(agency_id: @engagement.agency_id, status: "active")
        .where(document_types: { status: "active" })
        .where(
          relationship_type: [ "any", @engagement.relationship_type ]
        )
        .order(:id)
    end

    def evaluate_requirement(requirement)
      return unless requirement.applies_to_engagement?(@engagement)

      candidates = matching_records(requirement).to_a.reject { |r| r.status == "voided" }
      best = pick_best_candidate(candidates)
      outcome = derive_outcome(best, requirement)
      rec_status = best&.status

      RequirementEvaluation.new(
        document_requirement_id: requirement.id,
        document_type_id: requirement.document_type_id,
        requirement_scope: requirement.requirement_scope,
        relationship_type: requirement.relationship_type,
        required: requirement.required?,
        verification_required: requirement.verification_required,
        requirement_outcome: outcome,
        record_review_status: rec_status,
        document_record_id: best&.id,
        expires_on: best&.expires_on
      )
    end

    def matching_records(requirement)
      scope = DocumentRecord.where(
        agency_id: @engagement.agency_id,
        document_type_id: requirement.document_type_id
      )

      case requirement.requirement_scope
      when "engagement"
        scope.where(engagement_id: @engagement.id)
      when "team_member"
        scope.where(team_member_id: @engagement.team_member_id)
      else
        scope.none
      end
    end

    def pick_best_candidate(records)
      return if records.empty?

      records.min_by { |r| sort_tuple(r) }
    end

    # Lower tuple is better. Tie-break: submitted_on DESC, created_at DESC.
    def sort_tuple(record)
      rank = candidate_rank(record)
      sub = record.submitted_on
      sub_key = sub ? -sub.jd : -record.created_at.to_date.jd
      [ rank, sub_key, -record.created_at.to_f ]
    end

    def candidate_rank(record)
      exp = expired?(record)

      case record.status
      when "verified"
        exp ? 5 : 1
      when "submitted"
        exp ? 4 : 2
      when "rejected"
        3
      else
        9
      end
    end

    def derive_outcome(record, requirement)
      return "missing" if record.blank?

      return "expired" if expired?(record)

      case record.status
      when "verified"
        expiring_soon?(record, requirement) ? "expiring_soon" : "satisfied"
      when "submitted"
        if requirement.verification_required
          "pending_verification"
        else
          expiring_soon?(record, requirement) ? "expiring_soon" : "satisfied"
        end
      when "rejected"
        "rejected"
      else
        "missing"
      end
    end

    def expired?(record)
      record.expires_on.present? && record.expires_on < @as_of_date
    end

    def expiring_soon?(record, requirement)
      return false if record.expires_on.blank?
      return false if expired?(record)

      window = requirement.expiring_soon_days ||
        requirement.document_type&.default_expiring_soon_days ||
         30

      last_ok = @as_of_date + window.days
      record.expires_on <= last_ok
    end

    def aggregate_readiness(rows)
      applicable = rows.reject { |r| r.requirement_outcome == "not_applicable" }
      return "not_applicable" if applicable.empty?

      required_rows = applicable.select(&:required)

      return "ready" if required_rows.empty?

      if required_rows.any? { |r| BLOCKING_OUTCOMES.include?(r.requirement_outcome) }
        return "not_ready"
      end

      return "warning" if required_rows.any? { |r| r.requirement_outcome == "expiring_soon" }

      "ready"
    end
  end
end

# frozen_string_literal: true

module Admin
  # Contractor-facing summary on admin engagement show (TC-09). Consumes Documents::ReadinessEvaluator output only.
  class ContractorClassificationSupportPresenter
    attr_reader :readiness, :document_types_by_id

    ROLLUP_RANK = {
      "missing" => 1,
      "expired" => 1,
      "rejected" => 1,
      "pending_verification" => 1,
      "expiring_soon" => 2,
      "satisfied" => 3,
      "not_applicable" => 4
    }.freeze

    PANEL_CATEGORIES = %w[tax_form contractor_agreement insurance classification_support certification].freeze

    CategoryRollup = Data.define(:category, :rollup_outcome, :rows)

    def initialize(engagement:, readiness:, document_types_by_id:)
      @engagement = engagement
      @readiness = readiness
      @document_types_by_id = document_types_by_id
    end

    def readiness_status
      @readiness.readiness_status
    end

    def as_of_date
      @readiness.as_of_date
    end

    def identity_rows
      rows = []
      party = @engagement.team_member&.party
      rows << [ "Team member", party&.display_name.presence || "—" ]
      rows << [ "Relationship type", @engagement.relationship_type ]
      rows << [ "Engagement status", @engagement.status ]
      rows << [ "Renewal (planning)", @engagement.renewal_on&.to_s || "—" ]

      if party&.person?
        pp = party.person_profile
        rows << [ "Legal name", [ pp&.first_name, pp&.last_name ].compact.join(" ").presence || "—" ]
      elsif party&.organization?
        op = party.organization_profile
        rows << [ "Legal name", op&.legal_name.presence || "—" ]
        rows << [ "DBA / trade name", op&.trade_name.presence || "—" ]
      end

      rows
    end

    def category_rollups
      by_cat = Hash.new { |h, k| h[k] = [] }
      @readiness.requirements.each do |row|
        dt = @document_types_by_id[row.document_type_id]
        next unless dt

        cat = dt.category
        next unless PANEL_CATEGORIES.include?(cat)

        by_cat[cat] << row
      end

      by_cat.map do |category, rs|
        outcome = worst_outcome(rs.map(&:requirement_outcome))
        CategoryRollup.new(category:, rollup_outcome: outcome, rows: rs)
      end.sort_by(&:category)
    end

    private

    def worst_outcome(outcomes)
      outcomes.min_by { |o| ROLLUP_RANK.fetch(o, 99) }
    end
  end
end

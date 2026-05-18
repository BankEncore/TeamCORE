# frozen_string_literal: true

module Team360
  # Turns EngagementSetupChecklistPresenter gaps into prioritized CTAs for Team360 (UX-2).
  # Does not duplicate readiness evaluator logic — consumes checklist rows only.
  class NextActionsPresenter
    include Rails.application.routes.url_helpers

    Action = Data.define(:label, :description, :href, :urgency, :source, :sort_key)

    DISPLAY_LIMIT = 7

    URGENCY_RANK = {
      blocking: 0,
      warning: 1,
      setup: 2,
      review: 3,
      optional: 4
    }.freeze

    ROW_SORT_ORDER = %i[
      basic_engagement_details
      current_placement
      supervision
      document_readiness
      contractor_classification
      compensation
      contractor_charges
      settlement
    ].freeze

    def initialize(team_member:, engagement:, snapshot:, checklist_presenter:)
      @team_member = team_member
      @engagement = engagement
      @snapshot = snapshot
      @checklist_presenter = checklist_presenter
    end

    def actions
      return [] if @checklist_presenter.blank?

      rows = gap_rows
      built = rows.filter_map { |row| build_action(row) }
      built.sort_by { |a| [ URGENCY_RANK[a.urgency], ROW_SORT_ORDER.index(a.sort_key) || 99 ] }
           .first(DISPLAY_LIMIT)
    end

    def more_actions?
      gap_rows.size > DISPLAY_LIMIT
    end

    private

    def gap_rows
      @checklist_presenter.rows.select { |r| %w[needs_attention warning].include?(r.bucket) }
    end

    # Full Team360 URL for post-save round-trip (Admin return navigation contract).
    def team360_return_path
      admin_team_member_team360_path(
        @team_member,
        **{ engagement_id: @engagement.id, as_of_date: @snapshot.as_of_date&.iso8601 }.compact
      )
    end

    def rt
      { team360_return_to: team360_return_path }
    end

    def build_action(row)
      urgency = row.bucket == "warning" ? :warning : :blocking

      href =
        case row.key
        when :basic_engagement_details
          edit_admin_engagement_path(@engagement, **rt)
        when :current_placement
          new_admin_engagement_placement_path(@engagement, **rt)
        when :supervision
          new_admin_engagement_supervision_assignment_path(@engagement, **rt)
        when :document_readiness
          # Canonical triage surface for requirement gaps / verification backlog.
          admin_document_workbench_path(**rt)
        when :contractor_classification
          admin_document_workbench_path(**rt)
        when :compensation
          new_admin_engagement_compensation_plan_assignment_path(@engagement, **rt)
        when :contractor_charges
          new_admin_engagement_contractor_charge_path(@engagement, **rt)
        when :settlement
          # Open charges on engagement before composing settlement lines / runs.
          admin_engagement_contractor_charges_path(@engagement, **rt)
        else
          return nil
        end

      Action.new(
        label: row.label,
        description: row.detail,
        href: href,
        urgency: urgency,
        source: "setup_checklist",
        sort_key: row.key
      )
    end
  end
end

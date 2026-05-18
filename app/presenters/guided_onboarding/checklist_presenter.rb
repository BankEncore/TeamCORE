# frozen_string_literal: true

module GuidedOnboarding
  # Derived onboarding checklist for `/admin/guided/*` flows (UX-3).
  # Reuses Documents::ReadinessEvaluator + Admin::EngagementSetupChecklistPresenter when an engagement exists.
  class ChecklistPresenter
    include Rails.application.routes.url_helpers

    Row = Data.define(
      :key,
      :status,
      :label,
      :detail,
      :primary_label,
      :primary_href,
      :secondary_label,
      :secondary_href
    )

    CHECKLIST_KEYS = %i[
      basic_engagement_details
      current_placement
      supervision
      document_readiness
      contractor_classification
      compensation
      contractor_charges
      settlement
    ].freeze

    GAP_PRIMARY_LABELS = {
      basic_engagement_details: "Edit engagement",
      current_placement: "Add placement",
      supervision: "Assign supervision",
      document_readiness: "Document workbench",
      contractor_classification: "Document workbench",
      compensation: "Add compensation",
      contractor_charges: "Add contractor charge",
      settlement: "Review charges"
    }.freeze

    def initialize(
      agency:,
      selected_party:,
      relationship_type:,
      org_flow:,
      guided_return_path:,
      search_q: nil,
      team_member_id_param: nil
    )
      @agency = agency
      @selected_party = selected_party
      @relationship_type = relationship_type
      @org_flow = org_flow
      @guided_return_path = guided_return_path
      @search_q = search_q
      @team_member_id_param = team_member_id_param
    end

    def rows
      list = []
      list << party_identity_row
      list << team_member_row
      list << engagement_shell_row
      if resolved_engagement
        engagement_checklist.rows.each do |r|
          next unless CHECKLIST_KEYS.include?(r.key)

          list << map_engagement_row(r)
        end
        list << activation_row
      end
      list.compact
    end

    private

    def rt
      { return_to: @guided_return_path, team360_return_to: @guided_return_path }
    end

    def resolved_team_member
      return @resolved_team_member if defined?(@resolved_team_member)

      party = @selected_party
      return @resolved_team_member = nil if party.blank?

      tm_param = @team_member_id_param.to_s
      if tm_param.match?(/\A\d+\z/)
        tm =
          TeamMember.where(agency_id: @agency.id, party_id: party.id).find_by(id: tm_param.to_i)
        return @resolved_team_member = tm if tm
      end

      @resolved_team_member = TeamMember.find_by(agency_id: @agency.id, party_id: party.id)
    end

    def resolved_engagement
      return @resolved_engagement if defined?(@resolved_engagement)

      tm = resolved_team_member
      return @resolved_engagement = nil if tm.blank?

      scope =
        Engagement.where(agency_id: @agency.id, team_member_id: tm.id, relationship_type: @relationship_type)
          .includes(
            :engagement_organization_placements,
            :engagement_supervision_assignments,
            :contractor_charges,
            :contractor_settlement_lines
          )

      @resolved_engagement =
        scope.find_by(status: "active") ||
        scope.where.not(status: Engagement::TERMINAL_STATUSES).order(updated_at: :desc).first ||
        scope.order(updated_at: :desc).first
    end

    def readiness_result
      return nil if resolved_engagement.blank?

      @readiness_result ||= Documents::ReadinessEvaluator.new(
        engagement: resolved_engagement,
        as_of_date: Date.current
      ).call
    end

    def engagement_checklist
      @engagement_checklist ||=
        Admin::EngagementSetupChecklistPresenter.new(
          engagement: resolved_engagement,
          document_readiness: readiness_result,
          as_of_date: Date.current,
          workforce_financial_assignment: CompensationPlanAssignment.current_for_engagement(resolved_engagement)
        )
    end

    def team360_path
      admin_team_member_team360_path(
        resolved_team_member,
        engagement_id: resolved_engagement.id,
        as_of_date: Date.current.iso8601
      )
    end

    def party_identity_row
      if @selected_party
        Row.new(
          key: :party_identity,
          status: "complete",
          label: "Party identity",
          detail: "#{@selected_party.display_name} selected.",
          primary_label: nil,
          primary_href: nil,
          secondary_label: "Party hub",
          secondary_href: admin_party_path(@selected_party)
        )
      else
        Row.new(
          key: :party_identity,
          status: "pending",
          label: "Party identity",
          detail: onboarding_party_identity_detail,
          primary_label: (@org_flow ? nil : "Create person party"),
          primary_href: (@org_flow ? nil : admin_new_person_party_path(**rt)),
          secondary_label: "Create organization party",
          secondary_href: admin_new_organization_party_path(**rt)
        )
      end
    end

    def onboarding_party_identity_detail
      parts = [ "Search below (or use workspace search) before creating a new party." ]
      q = @search_q.to_s.strip
      if q.present? && q.length < 2
        parts << "Enter at least two characters to search."
      end
      parts.join(" ")
    end

    def team_member_row
      party = @selected_party
      if party.blank?
        return Row.new(
          key: :team_member_record,
          status: "not_applicable",
          label: "Team member",
          detail: "Select a party first.",
          primary_label: nil,
          primary_href: nil,
          secondary_label: nil,
          secondary_href: nil
        )
      end

      tm = resolved_team_member
      if tm
        Row.new(
          key: :team_member_record,
          status: "complete",
          label: "Team member",
          detail: "Team membership exists for this party.",
          primary_label: nil,
          primary_href: nil,
          secondary_label: "Open record",
          secondary_href: admin_team_member_path(tm)
        )
      else
        Row.new(
          key: :team_member_record,
          status: "pending",
          label: "Team member",
          detail: "Create a team member linking this party to your agency workspace.",
          primary_label: "New team member",
          primary_href: new_admin_team_member_path(party_id: party.id, **rt),
          secondary_label: "Pick party on form",
          secondary_href: new_admin_team_member_path(**rt)
        )
      end
    end

    def engagement_shell_row
      tm = resolved_team_member
      if tm.blank?
        return Row.new(
          key: :engagement_record,
          status: "not_applicable",
          label: "Engagement",
          detail: "Needs a team member first.",
          primary_label: nil,
          primary_href: nil,
          secondary_label: nil,
          secondary_href: nil
        )
      end

      eng = resolved_engagement
      if eng
        Row.new(
          key: :engagement_record,
          status: "complete",
          label: "Engagement",
          detail: "Found #{@relationship_type.tr("_", " ")} engagement.",
          primary_label: nil,
          primary_href: nil,
          secondary_label: "Open Team360",
          secondary_href: team360_path
        )
      else
        Row.new(
          key: :engagement_record,
          status: "pending",
          label: "Engagement",
          detail: "Create an engagement with relationship type #{@relationship_type.tr("_", " ")}.",
          primary_label: "New engagement",
          primary_href: new_admin_engagement_path(relationship_type: @relationship_type, team_member_id: tm.id, **rt),
          secondary_label: nil,
          secondary_href: nil
        )
      end
    end

    def map_engagement_row(row)
      gap = %w[needs_attention warning].include?(row.bucket)
      primary_label = gap ? GAP_PRIMARY_LABELS[row.key] : nil
      primary_href = gap ? href_for_engagement_row(row) : nil

      secondary_label = (!gap && row.bucket == "complete") ? "Open Team360" : nil
      secondary_href = (!gap && row.bucket == "complete") ? team360_path : nil

      Row.new(
        key: row.key,
        status: row.bucket,
        label: row.label,
        detail: row.detail,
        primary_label: primary_label,
        primary_href: primary_href,
        secondary_label: secondary_label,
        secondary_href: secondary_href
      )
    end

    def href_for_engagement_row(row)
      eng = resolved_engagement
      tm = resolved_team_member

      case row.key
      when :basic_engagement_details
        edit_admin_engagement_path(eng, **rt)
      when :current_placement
        new_admin_engagement_placement_path(eng, **rt)
      when :supervision
        new_admin_engagement_supervision_assignment_path(eng, **rt)
      when :document_readiness, :contractor_classification
        admin_document_workbench_path(**rt)
      when :compensation
        new_admin_engagement_compensation_plan_assignment_path(eng, **rt)
      when :contractor_charges
        new_admin_engagement_contractor_charge_path(eng, **rt)
      when :settlement
        admin_engagement_contractor_charges_path(eng, **rt)
      else
        admin_team_member_path(tm)
      end
    end

    def activation_row
      rs = readiness_result.readiness_status
      status =
        case rs
        when "ready" then "complete"
        when "warning" then "warning"
        when "not_applicable" then "not_applicable"
        else "needs_attention"
        end

      detail =
        case rs
        when "ready"
          "Document evaluator: ready — confirm remaining checklist rows in Team360."
        when "warning"
          "Document evaluator: warning — review requirements and workbench queue."
        when "not_applicable"
          "Document evaluator marked not applicable for this engagement."
        else
          "Document evaluator: not ready — address blocking requirements."
        end

      Row.new(
        key: :activation_readiness,
        status: status,
        label: "Activation readiness",
        detail: detail,
        primary_label: "Open Team360",
        primary_href: team360_path,
        secondary_label: nil,
        secondary_href: nil
      )
    end
  end
end

# frozen_string_literal: true

module Team360
  class ProfileAssembler
    include Rails.application.routes.url_helpers

    def initialize(team_member:, agency:, current_user: nil, as_of_date: Date.current, focused_engagement_id: nil)
      @team_member = team_member
      @agency = agency
      @current_user = current_user
      @as_of_date = as_of_date
      @focused_engagement_id = focused_engagement_id
    end

    def call
      party = @team_member.party
      engagements = @team_member.engagements.to_a.sort_by(&:id)

      focused =
        Team360::FocusedEngagementResolver.call(
          team_member: @team_member,
          preferred_engagement_id: @focused_engagement_id
        )

      engagement_summaries =
        engagements.map do |e|
          {
            id: e.id,
            relationship_type: e.relationship_type,
            status: e.status,
            title: e.title,
            start_on: e.start_on,
            end_on: e.end_on,
            expected_end_on: e.expected_end_on,
            renewal_on: e.renewal_on,
            employee_path: e.employee_path?,
            contractor_class: e.contractor_class?,
            terminal: e.terminal?,
            suspended: e.suspended?,
            operational_blocked: e.operational_forward_work_blocked_by_status?
          }
        end

      current_ids = engagements.select { |e| e.status == "active" }.map(&:id)

      organization_context = build_organization_context(focused)
      readiness_result = build_readiness(focused)
      doc_types_by_id, records_by_id = build_document_lookups(readiness_result)

      Team360::ProfileSnapshot.new(
        as_of_date: @as_of_date,
        focused_engagement_id: focused&.id,
        identity: build_identity(party),
        contacts: build_contacts(party),
        engagement_summaries: engagement_summaries,
        current_engagement_ids: current_ids,
        organization_context: organization_context,
        readiness_result: readiness_result,
        document_types_by_id: doc_types_by_id,
        records_by_id: records_by_id,
        subcontractor_rows: build_subcontractor_rows(party),
        workforce_financial: build_workforce_financial(focused),
        payroll_prep_panel: build_payroll_prep_panel(focused),
        weekly_timesheets_panel: build_weekly_timesheets_panel(focused),
        leave_panel: build_leave_panel(focused)
      )
    end

    private

    def build_identity(party)
      {
        display_name: party.display_name,
        party_type: party.party_type,
        party_id: party.id,
        team_member_number: @team_member.team_member_number,
        team_member_status: @team_member.status,
        team_member_id: @team_member.id
      }
    end

    def build_contacts(party)
      party
        .party_contact_methods
        .order(:id)
        .map do |cm|
          {
            id: cm.id,
            contact_type: cm.contact_type,
            value: cm.value,
            is_primary: cm.is_primary,
            status: cm.status
          }
        end
    end

    def build_organization_context(focused_engagement)
      return nil unless focused_engagement

      placement =
        Team360::OrgEffectiveRow.pick(
          focused_engagement.engagement_organization_placements.order(:effective_start_on).to_a,
          @as_of_date
        )

      supervision =
        Team360::OrgEffectiveRow.pick(
          focused_engagement.engagement_supervision_assignments.order(:effective_start_on).to_a,
          @as_of_date
        )

      supervisor_engagement = supervision&.supervisor_engagement
      supervisor_party_name = supervisor_engagement&.team_member&.party&.display_name

      dept = placement&.department
      loc = placement&.location
      team = placement&.team

      {
        engagement_id: focused_engagement.id,
        placement_id: placement&.id,
        department: dept && { id: dept.id, name: dept.name, status: dept.status },
        location: loc && { id: loc.id, name: loc.name, status: loc.status },
        team: team && { id: team.id, name: team.name, status: team.status },
        placement_effective: placement && {
          start_on: placement.effective_start_on,
          end_on: placement.effective_end_on
        },
        supervision: supervision && {
          id: supervision.id,
          supervisor_engagement_id: supervision.supervisor_engagement_id,
          supervisor_display: supervisor_party_name,
          relationship_type: supervision.relationship_type,
          start_on: supervision.effective_start_on,
          end_on: supervision.effective_end_on
        }
      }
    end

    def build_readiness(focused_engagement)
      return nil unless focused_engagement

      Documents::ReadinessEvaluator.new(engagement: focused_engagement, as_of_date: @as_of_date).call
    end

    def build_document_lookups(readiness_result)
      Documents::ReadinessDocumentLookups.indexes_from(readiness_result)
    end

    def build_workforce_financial(focused_engagement)
      return { focused_engagement_id: nil } unless focused_engagement

      assignment = CompensationPlanAssignment.current_for_engagement(focused_engagement, as_of: @as_of_date)
      draw = focused_engagement.commission_draw_balance
      show_draw =
        focused_engagement.allows_employee_commission_draw? &&
        (@current_user.nil? || @current_user.team360_show_employee_draw_balance?)

      out = {
        focused_engagement_id: focused_engagement.id,
        relationship_type: focused_engagement.relationship_type,
        assignment_summary: assignment && {
          plan_name: assignment.snapshot_plan_name,
          plan_type: assignment.snapshot_plan_type,
          effective_start_on: assignment.effective_start_on,
          effective_end_on: assignment.effective_end_on,
          commission_rate_bps: assignment.snapshot_commission_rate_bps,
          minimum_amount_cents: assignment.snapshot_minimum_amount_cents
        },
        draw_balance_cents: (show_draw ? draw&.balance_cents : nil)
      }

      out[:admin_links] = {
        revenue_inputs: admin_engagement_revenue_inputs_path(focused_engagement),
        commission_calculations: admin_engagement_commission_calculations_path(focused_engagement),
        settlement_runs_index: admin_contractor_settlement_runs_path
      }
      if focused_engagement.allows_contractor_charges_and_settlement?
        out[:admin_links][:contractor_charges] = admin_engagement_contractor_charges_path(focused_engagement)
      end

      if focused_engagement.allows_contractor_charges_and_settlement?
        charges = focused_engagement.contractor_charges.where(status: %w[open draft])
        overdue_scope = charges.where.not(due_on: nil).where("due_on < ?", @as_of_date)
        upcoming_scope = charges.where.not(due_on: nil).where("due_on >= ?", @as_of_date)
        recent_recoveries =
          ContractorChargeRecovery
            .joins(:contractor_charge)
            .where(contractor_charges: { engagement_id: focused_engagement.id })
            .order(occurred_on: :desc, id: :desc)
            .limit(5)
            .map do |r|
              {
                id: r.id,
                amount_cents: r.amount_cents,
                occurred_on: r.occurred_on,
                source_type: r.source_type,
                contractor_charge_id: r.contractor_charge_id
              }
            end
        recent_waivers =
          ContractorChargeWaiver
            .joins(:contractor_charge)
            .where(contractor_charges: { engagement_id: focused_engagement.id })
            .order(id: :desc)
            .limit(5)
            .map do |w|
              {
                id: w.id,
                amount_cents: w.amount_cents,
                created_at: w.created_at,
                contractor_charge_id: w.contractor_charge_id
              }
            end

        open_settlement_runs =
          ContractorSettlementRun
            .where(agency_id: @agency.id, status: %w[draft calculated])
            .order(id: :desc)
            .limit(5)
            .map do |r|
              {
                id: r.id,
                status: r.status,
                period_start_on: r.period_start_on,
                period_end_on: r.period_end_on
              }
            end

        out[:contractor_charges] = {
          open_count: charges.count,
          open_balance_cents: charges.sum(:open_balance_cents),
          past_due_count: overdue_scope.count,
          past_due_balance_cents: overdue_scope.sum(:open_balance_cents),
          next_due_on: upcoming_scope.minimum(:due_on),
          recent_recoveries:,
          recent_waivers:
        }

        line_records =
          ContractorSettlementLine
            .includes(:contractor_settlement_run)
            .where(engagement_id: focused_engagement.id)
            .order(id: :desc)
            .limit(5)
            .to_a

        settlement_lines =
          line_records.map do |ln|
            run = ln.contractor_settlement_run
            {
              line_id: ln.id,
              run_id: run.id,
              run_status: run.status,
              period_start_on: run.period_start_on,
              period_end_on: run.period_end_on,
              net_cents: ln.net_settlement_cents
            }
          end

        ln_latest = line_records.first
        out[:last_settlement] =
          if ln_latest
            run = ln_latest.contractor_settlement_run
            {
              run_id: run.id,
              status: run.status,
              period_start_on: run.period_start_on,
              period_end_on: run.period_end_on,
              net_cents: ln_latest.net_settlement_cents
            }
          end
        out[:settlement] = {
          open_runs: open_settlement_runs,
          recent_lines: settlement_lines
        }
      end

      out
    end

    def build_payroll_prep_panel(focused_engagement)
      return nil unless focused_engagement&.employee_path?

      period =
        PayPeriod
          .where(agency_id: @agency.id)
          .where("start_on <= ? AND end_on >= ?", @as_of_date, @as_of_date)
          .first
      return nil unless period

      batch =
        PayrollInputBatch
          .where(pay_period_id: period.id, status: %w[finalized exported])
          .order(Arel.sql("CASE status WHEN 'exported' THEN 0 ELSE 1 END"), finalized_at: :desc)
          .first
      return nil unless batch

      rows =
        batch.payroll_input_rows.where(engagement_id: focused_engagement.id).order(:earning_code, :id).map do |r|
          {
            earning_code: r.earning_code,
            direction: r.direction,
            hours: r.hours&.to_s("F"),
            amount: r.amount&.to_s("F"),
            currency: r.currency
          }
        end

      out = {
        pay_period_id: period.id,
        pay_period_range: "#{period.start_on} – #{period.end_on}",
        batch_reference: batch.reference_number,
        batch_status: batch.status,
        rows: rows
      }

      if batch.payroll_export.present?
        ex = batch.payroll_export
        out[:payroll_export_sequence] = ex.export_sequence
        out[:payroll_export_at] = ex.exported_at&.iso8601
        out[:payroll_export_file_present] = ex.export_file.attached?
      end

      out
    end

    def build_weekly_timesheets_panel(focused_engagement)
      return nil unless focused_engagement&.employee_path?

      focused_engagement
        .weekly_timesheets
        .includes(:weekly_timesheet_approval_events)
        .order(week_start_on: :desc)
        .limit(16)
        .map { |sheet| serialize_weekly_timesheet_panel_row(sheet) }
    end

    def serialize_weekly_timesheet_panel_row(sheet)
      ot = Payroll::TimesheetOvertimePresenter.for_timesheet(sheet)
      events =
        sheet.weekly_timesheet_approval_events.recent_first.limit(8).map do |ev|
          {
            id: ev.id,
            event_type: ev.event_type,
            transition_from: ev.transition_from,
            transition_to: ev.transition_to,
            occurred_at: ev.occurred_at,
            actor_email: ev.actor&.email,
            reason: ev.metadata_hash["reason"]
          }
        end

      {
        id: sheet.id,
        week_start_on: sheet.week_start_on,
        week_end_on: sheet.week_end_on,
        status: sheet.status,
        submitted_at: sheet.submitted_at,
        approved_at: sheet.approved_at,
        regular_hours: ot.regular_hours.to_s("F"),
        overtime_hours: ot.overtime_hours.to_s("F"),
        overtime_visibility: ot.visibility_mode.to_s,
        approval_events: events
      }
    end

    def build_leave_panel(focused_engagement)
      return nil unless focused_engagement&.employee_path?

      balances =
        focused_engagement
          .leave_balances
          .includes(:leave_type)
          .order(:id)
          .map do |b|
            {
              leave_type_code: b.leave_type.code,
              balance_hours: BigDecimal(b.balance_hours.to_s).to_s("F")
            }
          end

      requests =
        focused_engagement
          .leave_requests
          .includes(:leave_type, :leave_request_days, leave_request_approval_events: :actor)
          .order(id: :desc)
          .limit(12)
          .map { |req| serialize_leave_request_panel_row(req) }

      { balances:, requests: }
    end

    def serialize_leave_request_panel_row(req)
      vis = Payroll::LeavePayrollVisibilityPresenter.for_leave_request(req)
      days =
        req.leave_request_days.sort_by(&:leave_date).map do |d|
          { leave_date: d.leave_date, hours: BigDecimal(d.hours.to_s).to_s("F") }
        end
      events =
        req.leave_request_approval_events.recent_first.limit(6).map do |ev|
          {
            occurred_at: ev.occurred_at,
            event_type: ev.event_type,
            transition_from: ev.transition_from,
            transition_to: ev.transition_to,
            actor_email: ev.actor&.email,
            actor_kind: ev.metadata_hash["actor_kind"],
            reason: ev.metadata_hash["reason"]
          }
        end

      {
        id: req.id,
        leave_type_code: req.leave_type.code,
        approval_policy: req.leave_type.approval_policy,
        auto_approved: req.auto_approved?,
        status: req.status,
        start_on: req.start_on,
        end_on: req.end_on,
        visibility_label: vis.visibility_label,
        days:,
        events:
      }
    end

    def build_subcontractor_rows(party)
      rels =
        PartyRelationship.where(
          agency_id: @agency.id,
          relationship_type: "subcontractor",
          target_party_id: party.id
        ).includes(:source_party).order(id: :asc).to_a

      sub_engagements =
        @team_member.engagements.select { |e| e.relationship_type == "subcontractor" }

      rels.map do |rel|
        promoted = sub_engagements.any?
        latest_sub = sub_engagements.max_by { |e| [ e.start_on || Date.new(1900, 1, 1), e.id ] }
        {
          id: rel.id,
          source_party: rel.source_party&.display_name,
          source_party_id: rel.source_party_id,
          status: rel.status,
          effective_start: rel.effective_start_date,
          effective_end: rel.effective_end_date,
          promoted: promoted,
          subcontractor_engagement_status: latest_sub&.status
        }
      end
    end
  end
end

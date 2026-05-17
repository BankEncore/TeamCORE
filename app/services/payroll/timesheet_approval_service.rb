# frozen_string_literal: true

module Payroll
  # Approval workflow façade: authorization, append-only audit events, weekly_timesheets mutation.
  class TimesheetApprovalService
    class Error < StandardError; end

    def initialize(weekly_timesheet:, actor:)
      @weekly_timesheet = weekly_timesheet
      @actor = actor
    end

    def approve!
      authorize!
      raise Error, "Only submitted timesheets can be approved." unless weekly_timesheet.status == "submitted"

      WeeklyTimesheet.transaction do
        record_event!(
          transition_from: "submitted",
          transition_to: "approved",
          event_type: "approved",
          metadata: {}
        )
        weekly_timesheet.update!(
          status: "approved",
          approved_at: Time.current,
          approved_by: actor
        )
      end
      weekly_timesheet.reload
    end

    # Returns the employee to draft for correction (audit: sent_back or returned_for_correction).
    def send_back_to_draft!(reason: nil, disposition: "sent_back")
      authorize!
      raise Error, "Only submitted timesheets can be returned for correction." unless weekly_timesheet.status == "submitted"

      etype =
        case disposition.to_s
        when "returned_for_correction" then "returned_for_correction"
        else "sent_back"
        end

      WeeklyTimesheet.transaction do
        record_event!(
          transition_from: "submitted",
          transition_to: "draft",
          event_type: etype,
          metadata: reason.present? ? { reason: reason.to_s } : {}
        )
        weekly_timesheet.update!(
          status: "draft",
          submitted_at: nil
        )
      end
      weekly_timesheet.reload
    end

    def reopen_to_draft!(reason: nil)
      authorize!
      unless weekly_timesheet.status == "approved"
        raise Error, "Only approved timesheets can be reopened to draft."
      end

      WeeklyTimesheet.transaction do
        record_event!(
          transition_from: "approved",
          transition_to: "draft",
          event_type: "reopened",
          metadata: reason.present? ? { reason: reason.to_s } : {}
        )
        weekly_timesheet.update!(
          status: "draft",
          submitted_at: nil,
          approved_at: nil,
          approved_by_id: nil
        )
      end
      weekly_timesheet.reload
    end

    private

    attr_reader :weekly_timesheet, :actor

    def authorize!
      unless Access.can_manage_weekly_timesheet_approval?(user: actor, weekly_timesheet: weekly_timesheet)
        raise Error, "Not permitted to manage timesheet approvals for this agency."
      end
    end

    def record_event!(transition_from:, transition_to:, event_type:, metadata:)
      meta =
        if metadata.is_a?(Hash) && metadata.present?
          metadata.deep_stringify_keys
        else
          {}
        end

      WeeklyTimesheetApprovalEvent.create!(
        weekly_timesheet: weekly_timesheet,
        actor: actor,
        occurred_at: Time.current,
        transition_from: transition_from,
        transition_to: transition_to,
        event_type: event_type,
        metadata: meta
      )
    end
  end
end

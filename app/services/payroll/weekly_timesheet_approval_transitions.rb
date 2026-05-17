# frozen_string_literal: true

module Payroll
  # Thin TC-24-owned transitions (schema + payroll integration); UX/policy layering ships with TC-24.
  class WeeklyTimesheetApprovalTransitions
    class Error < StandardError; end

    def initialize(timesheet:, actor:)
      @timesheet = timesheet
      @actor = actor
    end

    def approve!
      raise Error, "Only submitted timesheets can be approved" unless timesheet.status == "submitted"

      timesheet.update!(
        status: "approved",
        approved_at: Time.current,
        approved_by: actor,
        rejected_at: nil,
        rejected_by_id: nil,
        rejection_reason: nil
      )
    end

    def reject!(reason: nil)
      raise Error, "Only submitted timesheets can be rejected" unless timesheet.status == "submitted"

      timesheet.update!(
        status: "rejected",
        rejected_at: Time.current,
        rejected_by: actor,
        rejection_reason: reason,
        approved_at: nil,
        approved_by_id: nil
      )
    end

    def send_back_to_draft!
      raise Error, "Only submitted timesheets can be sent back to draft" unless timesheet.status == "submitted"

      timesheet.update!(
        status: "draft",
        submitted_at: nil
      )
    end

    def reopen_to_draft!
      unless %w[approved rejected].include?(timesheet.status)
        raise Error, "Only approved or rejected timesheets can be reopened to draft"
      end

      timesheet.update!(
        status: "draft",
        submitted_at: nil,
        approved_at: nil,
        approved_by_id: nil,
        rejected_at: nil,
        rejected_by_id: nil,
        rejection_reason: nil
      )
    end

    private

    attr_reader :timesheet, :actor
  end
end

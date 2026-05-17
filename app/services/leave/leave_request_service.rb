# frozen_string_literal: true

module Leave
  # Workflow façade: authorization, append-only events, balance consume/restore for tracked paid types.
  class LeaveRequestService
    class Error < StandardError; end

    SYSTEM_ACTOR_KIND = "system_policy"

    def initialize(leave_request:, actor:)
      @leave_request = leave_request
      @actor = actor
    end

    def submit!
      authorize_manage!
      raise Error, "Only draft requests can be submitted." unless leave_request.status == "draft"

      validate_days_present!

      policy = Leave::ApprovalPolicy.new(leave_request)
      submit_errs =
        if policy.auto_approve?
          policy.submit_errors_for_auto_type
        else
          policy.submit_errors_for_manual_type
        end
      raise Error, submit_errs.first if submit_errs.any?

      LeaveRequest.transaction do
        record_event!(
          transition_from: "draft",
          transition_to: "submitted",
          event_type: "submitted",
          metadata: {},
          audit_actor: actor
        )
        leave_request.update!(
          status: "submitted",
          submitted_at: Time.current
        )

        approve_after_submit_if_auto! if policy.auto_approve?
      end
      leave_request.reload
    end

    def cancel!(reason: nil)
      authorize_manage!
      case leave_request.status
      when "draft"
        LeaveRequest.transaction do
          record_event!(
            transition_from: "draft",
            transition_to: "cancelled",
            event_type: "cancelled",
            metadata: meta_reason(reason),
            audit_actor: actor
          )
          leave_request.update!(status: "cancelled", cancellation_reason: reason&.to_s&.strip)
        end
      when "submitted"
        LeaveRequest.transaction do
          record_event!(
            transition_from: "submitted",
            transition_to: "cancelled",
            event_type: "cancelled",
            metadata: meta_reason(reason),
            audit_actor: actor
          )
          leave_request.update!(status: "cancelled", cancellation_reason: reason&.to_s&.strip, submitted_at: nil)
        end
      when "approved"
        LeaveRequest.transaction do
          restore_balance_if_needed!
          record_event!(
            transition_from: "approved",
            transition_to: "cancelled",
            event_type: "cancelled",
            metadata: meta_reason(reason),
            audit_actor: actor
          )
          leave_request.update!(
            status: "cancelled",
            cancellation_reason: reason&.to_s&.strip,
            submitted_at: nil,
            reviewed_by_id: nil,
            reviewed_at: nil,
            review_notes: nil
          )
        end
      else
        raise Error, "This leave request cannot be cancelled from its current status."
      end
      leave_request.reload
    end

    def approve!(review_notes: nil)
      authorize_manage!
      raise Error, "Only submitted requests can be approved." unless leave_request.status == "submitted"

      validate_days_present!

      LeaveRequest.transaction do
        policy = Leave::ApprovalPolicy.new(leave_request.reload)
        appr_errs = policy.approval_errors
        raise Error, appr_errs.first if appr_errs.any?

        consume_balance_if_needed!
        record_event!(
          transition_from: "submitted",
          transition_to: "approved",
          event_type: "approved",
          metadata: {},
          audit_actor: actor
        )
        leave_request.update!(
          status: "approved",
          reviewed_by: actor,
          reviewed_at: Time.current,
          review_notes: review_notes&.to_s&.strip.presence
        )
      end
      leave_request.reload
    end

    def reject!(review_notes: nil)
      authorize_manage!
      raise Error, "Only submitted requests can be rejected." unless leave_request.status == "submitted"

      LeaveRequest.transaction do
        record_event!(
          transition_from: "submitted",
          transition_to: "rejected",
          event_type: "rejected",
          metadata: {},
          audit_actor: actor
        )
        leave_request.update!(
          status: "rejected",
          reviewed_by: actor,
          reviewed_at: Time.current,
          review_notes: review_notes&.to_s&.strip.presence,
          submitted_at: nil
        )
      end
      leave_request.reload
    end

    def reopen_to_draft!(reason: nil)
      authorize_manage!
      raise Error, "Only approved requests can be reopened to draft." unless leave_request.status == "approved"

      LeaveRequest.transaction do
        restore_balance_if_needed!
        record_event!(
          transition_from: "approved",
          transition_to: "draft",
          event_type: "reopened",
          metadata: meta_reason(reason),
          audit_actor: actor
        )
        leave_request.update!(
          status: "draft",
          submitted_at: nil,
          reviewed_by_id: nil,
          reviewed_at: nil,
          review_notes: nil
        )
      end
      leave_request.reload
    end

    private

    attr_reader :leave_request, :actor

    def approve_after_submit_if_auto!
      policy = Leave::ApprovalPolicy.new(leave_request.reload)
      appr_errs = policy.approval_errors
      raise Error, appr_errs.first if appr_errs.any?

      consume_balance_if_needed!
      record_event!(
        transition_from: "submitted",
        transition_to: "approved",
        event_type: "approved",
        metadata: {},
        audit_actor: nil
      )
      leave_request.update!(
        status: "approved",
        reviewed_by: nil,
        reviewed_at: Time.current,
        review_notes: nil
      )
    end

    def authorize_manage!
      unless Leave::Access.can_manage_leave_request?(user: actor, leave_request: leave_request)
        raise Error, "Not permitted to manage leave requests for this agency."
      end
    end

    def validate_days_present!
      leave_request.reload
      if leave_request.leave_request_days.empty?
        raise Error, "Leave request must include at least one day with hours."
      end

      total = leave_request.total_scheduled_hours
      raise Error, "Total scheduled hours must be greater than zero." if total <= 0
    end

    def scheduled_hours
      leave_request.leave_request_days.sum { |d| BigDecimal(d.hours.to_s) }
    end

    def consume_balance_if_needed!
      lt = leave_request.leave_type
      return unless lt.balance_tracked? && lt.paid?

      hours = scheduled_hours
      bal = LeaveBalance.lock.find_or_initialize_by(engagement_id: leave_request.engagement_id, leave_type_id: lt.id)
      bal.balance_hours = BigDecimal("0") if bal.balance_hours.nil?
      # find_or_initialize may create invalid record until save — balance_tracked validated on LeaveBalance
      unless lt.balance_tracked?
        return
      end

      if BigDecimal(bal.balance_hours.to_s) < hours
        raise Error, "Insufficient leave balance for this leave type."
      end

      bal.balance_hours = BigDecimal(bal.balance_hours.to_s) - hours
      bal.save!
    end

    def restore_balance_if_needed!
      lt = leave_request.leave_type
      return unless lt.balance_tracked? && lt.paid?

      hours = scheduled_hours
      bal = LeaveBalance.lock.find_or_initialize_by(engagement_id: leave_request.engagement_id, leave_type_id: lt.id)
      bal.balance_hours = BigDecimal("0") if bal.balance_hours.nil?
      bal.balance_hours = BigDecimal(bal.balance_hours.to_s) + hours
      bal.save!
    end

    def meta_reason(reason)
      reason.present? ? { reason: reason.to_s } : {}
    end

    def record_event!(transition_from:, transition_to:, event_type:, metadata:, audit_actor:)
      meta =
        if metadata.is_a?(Hash) && metadata.present?
          metadata.deep_stringify_keys
        else
          {}
        end

      meta["actor_kind"] = SYSTEM_ACTOR_KIND if audit_actor.nil?

      LeaveRequestApprovalEvent.create!(
        leave_request: leave_request,
        actor: audit_actor,
        occurred_at: Time.current,
        transition_from: transition_from,
        transition_to: transition_to,
        event_type: event_type,
        metadata: meta
      )
    end
  end
end

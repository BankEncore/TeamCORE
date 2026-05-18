# frozen_string_literal: true

module Leave
  # Policy gates for leave submission and approval (TC-26). No mutations.
  class ApprovalPolicy
    OVERLAP_MESSAGE = "Leave overlaps existing submitted or approved leave."
    BALANCE_MESSAGE = "Insufficient leave balance for this leave type."

    def initialize(leave_request)
      @leave_request = leave_request
    end

    def auto_approve?
      leave_type.approval_policy == "auto"
    end

    def manual_approval_required?
      leave_type.approval_policy == "manual"
    end

    def overlap_violation?
      dates = positive_hour_leave_dates
      return false if dates.empty?

      scope =
        LeaveRequestDay
          .joins(:leave_request)
          .merge(LeaveRequest.where(engagement_id: leave_request.engagement_id, status: %w[submitted approved]))
          .where(leave_date: dates)
          .where("leave_request_days.hours > 0")

      scope = scope.where.not(leave_request_id: leave_request.id) if leave_request.persisted?

      scope.exists?
    end

    def balance_insufficient?
      lt = leave_type
      return false unless lt.balance_tracked? && lt.paid?

      hours = leave_request.total_scheduled_hours
      return false if hours <= 0

      bal = LeaveBalance.find_by(engagement_id: leave_request.engagement_id, leave_type_id: lt.id)
      available = bal.present? ? BigDecimal(bal.balance_hours.to_s) : BigDecimal("0")
      available < hours
    end

    # Manual submit: overlap only (balance checked at approve).
    def submit_errors_for_manual_type
      errors = []
      errors << OVERLAP_MESSAGE if overlap_violation?
      errors
    end

    # Auto submit path ends in approve — overlap + balance before any transition.
    def submit_errors_for_auto_type
      errors = []
      errors << OVERLAP_MESSAGE if overlap_violation?
      errors << BALANCE_MESSAGE if balance_insufficient?
      errors
    end

    def approval_errors
      errors = []
      errors << OVERLAP_MESSAGE if overlap_violation?
      errors << BALANCE_MESSAGE if balance_insufficient?
      errors
    end

    private

    attr_reader :leave_request

    def leave_type
      leave_request.leave_type
    end

    def positive_hour_leave_dates
      leave_request
        .leave_request_days
        .reject(&:marked_for_destruction?)
        .filter_map do |d|
          next if d.leave_date.blank?
          next unless BigDecimal(d.hours.to_s) > 0

          d.leave_date
        end
        .uniq
    end
  end
end

# frozen_string_literal: true

module Leave
  class LeaveBalanceAdjustmentService
    class Error < StandardError; end

    def self.call(leave_balance:, adjustment_hours:, reason:, actor:)
      new(leave_balance:, adjustment_hours:, reason:, actor:).call
    end

    def initialize(leave_balance:, adjustment_hours:, reason:, actor:)
      @leave_balance = leave_balance
      @adjustment_hours = adjustment_hours
      @reason = reason
      @actor = actor
    end

    def call
      unless Leave::Access.can_adjust_leave_balance?(user: actor, leave_balance: leave_balance)
        raise Error, "Not permitted to adjust leave balances for this agency."
      end

      adj = BigDecimal(adjustment_hours.to_s)
      raise Error, "Reason can't be blank." if reason.blank?

      LeaveBalance.transaction do
        leave_balance.lock!
        leave_balance.balance_hours = BigDecimal(leave_balance.balance_hours.to_s) + adj
        leave_balance.save!
        LeaveBalanceAdjustment.create!(
          leave_balance: leave_balance,
          adjustment_hours: adj,
          reason: reason.to_s.strip,
          adjusted_by: actor,
          adjusted_at: Time.current
        )
      end
      leave_balance.reload
    end

    private

    attr_reader :leave_balance, :adjustment_hours, :reason, :actor
  end
end

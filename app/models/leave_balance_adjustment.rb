# frozen_string_literal: true

class LeaveBalanceAdjustment < ApplicationRecord
  belongs_to :leave_balance, inverse_of: :leave_balance_adjustments
  belongs_to :adjusted_by, class_name: "User", inverse_of: :leave_balance_adjustments_as_actor

  validates :adjustment_hours, numericality: true
  validates :reason, presence: true
  validates :adjusted_at, presence: true
end

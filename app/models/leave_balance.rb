# frozen_string_literal: true

class LeaveBalance < ApplicationRecord
  belongs_to :engagement, inverse_of: :leave_balances
  belongs_to :leave_type, inverse_of: :leave_balances
  has_many :leave_balance_adjustments, inverse_of: :leave_balance, dependent: :restrict_with_exception

  validates :balance_hours, numericality: true
  validates :leave_type_id, uniqueness: { scope: :engagement_id }
  validate :leave_type_must_be_balance_tracked

  private

  def leave_type_must_be_balance_tracked
    return if leave_type.blank?

    unless leave_type.balance_tracked?
      errors.add(:leave_type_id, "must be a balance-tracked leave type")
    end
  end
end

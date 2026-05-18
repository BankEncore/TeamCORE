# frozen_string_literal: true

class PayrollInputRow < ApplicationRecord
  DIRECTIONS = %w[earning deduction].freeze

  belongs_to :payroll_input_batch
  belongs_to :engagement
  belongs_to :source, polymorphic: true, optional: true

  validates :earning_code, presence: true
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :currency, presence: true
  validate :hours_or_amount_present

  private

  def hours_or_amount_present
    return if hours.present? || amount.present?

    errors.add(:base, "Either hours or amount must be present")
  end
end

# frozen_string_literal: true

class PayrollInputAdjustment < ApplicationRecord
  belongs_to :payroll_input_batch
  belongs_to :payroll_adjustment_code
  belongs_to :engagement

  validates :currency, presence: true
  validate :batch_must_be_draft
  validate :hours_or_amount_present

  private

  def batch_must_be_draft
    return if payroll_input_batch.blank?
    return if payroll_input_batch.draft?

    errors.add(:payroll_input_batch, "must be a draft batch")
  end

  def hours_or_amount_present
    return if hours.present? || amount.present?

    errors.add(:base, "Either hours or amount must be present")
  end
end

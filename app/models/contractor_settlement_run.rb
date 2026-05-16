# frozen_string_literal: true

class ContractorSettlementRun < ApplicationRecord
  belongs_to :agency
  has_many :contractor_settlement_lines, dependent: :restrict_with_exception
  has_many :contractor_settlement_run_events, dependent: :destroy

  STATUSES = %w[draft calculated finalized paid_recorded voided].freeze

  validates :period_start_on, :period_end_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :period_order

  private

  def period_order
    return if period_start_on.blank? || period_end_on.blank?
    return if period_end_on >= period_start_on

    errors.add(:period_end_on, "must be on or after period_start_on")
  end
end

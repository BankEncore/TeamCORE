# frozen_string_literal: true

class CommissionCalculation < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement
  belongs_to :pay_period, optional: true
  belongs_to :revenue_input, optional: true
  has_many :draw_balance_events, dependent: :restrict_with_exception
  has_many :contractor_settlement_line_commission_calculations, dependent: :restrict_with_exception
  has_many :contractor_settlement_lines, through: :contractor_settlement_line_commission_calculations

  STATUSES = %w[draft finalized].freeze

  validates :commission_rate_bps, :commissionable_revenue_cents, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :engagement_in_agency

  def finalized?
    status == "finalized"
  end

  private

  def engagement_in_agency
    return if engagement.blank? || agency_id.blank?
    return if engagement.agency_id == agency_id

    errors.add(:agency_id, "must match engagement")
  end
end

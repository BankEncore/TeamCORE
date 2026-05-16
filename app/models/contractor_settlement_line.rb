# frozen_string_literal: true

class ContractorSettlementLine < ApplicationRecord
  belongs_to :contractor_settlement_run
  belongs_to :agency
  belongs_to :engagement
  has_many :contractor_settlement_line_revenue_inputs, dependent: :destroy
  has_many :revenue_inputs, through: :contractor_settlement_line_revenue_inputs
  has_many :contractor_settlement_line_commission_calculations, dependent: :destroy
  has_many :commission_calculations, through: :contractor_settlement_line_commission_calculations
  has_many :contractor_charge_recoveries, dependent: :restrict_with_exception

  validate :engagement_eligible_for_settlement
  validate :non_negative_net

  private

  def engagement_eligible_for_settlement
    return if engagement.blank?

    unless engagement.allows_contractor_charges_and_settlement?
      errors.add(:engagement, "must be a contractor engagement for settlement lines")
    end
  end

  def non_negative_net
    return if net_settlement_cents.nil?
    return if net_settlement_cents >= 0

    errors.add(:net_settlement_cents, "cannot be negative in MVP")
  end
end

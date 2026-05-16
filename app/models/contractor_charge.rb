# frozen_string_literal: true

class ContractorCharge < ApplicationRecord
  include CurrencyCentsFields

  belongs_to :agency
  belongs_to :engagement
  has_many :contractor_charge_waivers, dependent: :restrict_with_exception
  has_many :contractor_charge_recoveries, dependent: :restrict_with_exception

  STATUSES = %w[draft open closed waived cancelled].freeze

  # Curated charge categories (brief §3.2); admins may still use legacy/custom values already stored.
  CHARGE_TYPES = %w[
    onboarding_fee
    annual_renewal_fee
    recurring_monthly_fee
    technology_fee
    insurance_pass_through
    supplier_chargeback
    reimbursable_expense
    asset_recovery
    other
  ].freeze

  def self.charge_type_select_values(current_type)
    (CHARGE_TYPES + [ current_type ].compact).uniq
  end

  currency_cents_fields :original_amount, :open_balance

  validates :charge_type, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :original_amount_cents, :open_balance_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :engagement_eligible_for_contractor_financials
  validate :open_balance_lte_original

  before_validation :sync_open_balance_with_new_record, on: :create

  private

  def sync_open_balance_with_new_record
    return unless new_record?
    self.open_balance_cents = original_amount_cents if open_balance_cents.nil? || (original_amount_cents && open_balance_cents > original_amount_cents)
  end

  def open_balance_lte_original
    return if original_amount_cents.nil? || open_balance_cents.nil?
    return if open_balance_cents <= original_amount_cents

    errors.add(:open_balance_cents, "cannot exceed original amount")
  end

  def engagement_eligible_for_contractor_financials
    return if engagement.blank?

    unless engagement.allows_contractor_charges_and_settlement?
      errors.add(:engagement, "must be individual_contractor or contractor_organization for contractor charges (MVP)")
    end
  end
end

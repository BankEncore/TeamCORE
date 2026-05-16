# frozen_string_literal: true

class ContractorChargeWaiver < ApplicationRecord
  include CurrencyCentsFields

  belongs_to :agency
  belongs_to :contractor_charge
  belongs_to :actor, class_name: "User"

  currency_cents_fields :amount

  validates :amount_cents, numericality: { greater_than: 0 }
  validate :charge_has_sufficient_balance

  after_create :apply_waiver_to_charge

  private

  def charge_has_sufficient_balance
    return if contractor_charge.blank?

    return if amount_cents.to_i <= contractor_charge.open_balance_cents

    errors.add(:amount_cents, "cannot exceed open balance")
  end

  def apply_waiver_to_charge
    ch = contractor_charge.reload
    new_bal = [ch.open_balance_cents - amount_cents, 0].max
    attrs = { open_balance_cents: new_bal }
    attrs[:status] = "waived" if new_bal.zero?
    ch.update!(attrs)
  end
end

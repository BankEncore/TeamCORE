# frozen_string_literal: true

class ContractorChargeRecovery < ApplicationRecord
  belongs_to :agency
  belongs_to :contractor_charge
  belongs_to :contractor_settlement_line, optional: true
  belongs_to :actor, class_name: "User", optional: true

  SOURCE_TYPES = %w[
    settlement_deduction
    settlement_deduction_reversal
    direct_payment
    invoice_reference
    manual_adjustment
  ].freeze

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :occurred_on, presence: true
end

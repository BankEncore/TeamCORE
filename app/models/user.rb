# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :user_agencies, dependent: :destroy
  has_many :agencies, through: :user_agencies
  has_many :verified_document_records, class_name: "DocumentRecord", foreign_key: :verified_by_id, inverse_of: :verified_by,
    dependent: :restrict_with_exception
  has_many :draw_balance_events, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_many :contractor_charge_waivers, foreign_key: :actor_id, inverse_of: :actor, dependent: :restrict_with_exception
  has_many :contractor_charge_recoveries, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Team360 §12.2 — employee draw visibility; permissive default until TC-29/30 role model.
  def team360_show_employee_draw_balance?
    true
  end
end

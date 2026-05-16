# frozen_string_literal: true

class CommissionDrawBalance < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement

  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :engagement_id, uniqueness: true
end

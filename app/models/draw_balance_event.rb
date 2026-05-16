# frozen_string_literal: true

class DrawBalanceEvent < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement
  belongs_to :commission_calculation, optional: true
  belongs_to :actor, class_name: "User", optional: true

  EVENT_TYPES = %w[draw_added recovery forgiveness correction].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

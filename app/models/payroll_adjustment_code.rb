# frozen_string_literal: true

class PayrollAdjustmentCode < ApplicationRecord
  DIRECTIONS = %w[earning deduction].freeze

  belongs_to :agency
  has_many :payroll_input_adjustments, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: { scope: :agency_id }
  validates :name, presence: true
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active_codes, -> { where(active: true) }
end

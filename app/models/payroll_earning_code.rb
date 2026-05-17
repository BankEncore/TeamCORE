# frozen_string_literal: true

class PayrollEarningCode < ApplicationRecord
  CATEGORIES = %w[worked_regular worked_overtime payable_leave].freeze

  validates :code, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :name, presence: true
  validates :position, numericality: { only_integer: true }

  scope :ordered, -> { order(:position, :code) }

  def self.regular_worked
    find_by!(code: "REG")
  end

  def self.overtime_worked
    find_by!(code: "OT")
  end
end

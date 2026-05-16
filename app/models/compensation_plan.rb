# frozen_string_literal: true

class CompensationPlan < ApplicationRecord
  belongs_to :agency
  has_many :compensation_plan_assignments, dependent: :restrict_with_exception

  PLAN_TYPES = %w[
    salary_only
    hourly_only
    commission_only
    salary_plus_commission
    hourly_plus_commission
  ].freeze

  STATUSES = %w[active inactive].freeze

  # MVP vocabulary for minimum-draw configuration (TC-16); extend as product adds bases.
  MINIMUM_COMMISSION_BASES = %w[fixed_amount].freeze

  # How commission above the minimum repays an outstanding draw balance.
  RECOVERY_RULES = %w[recover_from_excess_commission none].freeze

  def self.minimum_basis_select_values(current)
    (MINIMUM_COMMISSION_BASES + [ current ].compact).uniq
  end

  def self.recovery_rule_select_values(current)
    (RECOVERY_RULES + [ current ].compact).uniq
  end

  validates :name, :plan_type, :status, presence: true
  validates :plan_type, inclusion: { in: PLAN_TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :active_catalog, -> { where(status: "active") }
end

# frozen_string_literal: true

class LeaveType < ApplicationRecord
  APPROVAL_POLICIES = %w[manual auto].freeze

  belongs_to :agency, inverse_of: :leave_types
  belongs_to :payroll_earning_code, optional: true
  has_many :leave_requests, dependent: :restrict_with_exception
  has_many :leave_balances, dependent: :restrict_with_exception

  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :agency_id }
  validates :approval_policy, inclusion: { in: APPROVAL_POLICIES }
  validate :paid_leave_must_map_earning_code

  scope :active, -> { where(active: true) }

  # Defaults used after migrations for agencies created later (migration seeds historic agencies).
  def self.seed_defaults_for_agency!(agency)
    specs = [
      { code: "VACATION", name: "Vacation / PTO", paid: true, balance_tracked: true, pec_code: "PTO" },
      { code: "SICK", name: "Sick", paid: true, balance_tracked: true, pec_code: "SICK" },
      { code: "UNPAID", name: "Unpaid leave", paid: false, balance_tracked: false },
      { code: "BEREAVEMENT", name: "Bereavement", paid: true, balance_tracked: false, pec_code: "PTO" },
      { code: "JURY", name: "Jury duty", paid: true, balance_tracked: false, pec_code: "HOL" }
    ]
    pec_cache = {}
    specs.each do |row|
      next if exists?(agency_id: agency.id, code: row[:code])

      pec_id =
        if row[:paid] && row[:pec_code]
          pec_cache[row[:pec_code]] ||= PayrollEarningCode.find_by(code: row[:pec_code])&.id
        end

      create!(
        agency_id: agency.id,
        code: row[:code],
        name: row[:name],
        paid: row[:paid],
        balance_tracked: row[:balance_tracked],
        active: true,
        approval_policy: "manual",
        payroll_earning_code_id: pec_id
      )
    end
  end

  private

  def paid_leave_must_map_earning_code
    return unless paid?

    errors.add(:payroll_earning_code_id, "must be present for paid leave types") if payroll_earning_code_id.blank?
  end
end

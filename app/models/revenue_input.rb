# frozen_string_literal: true

class RevenueInput < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement
  belongs_to :pay_period, optional: true
  has_many :commission_calculations, dependent: :restrict_with_exception
  has_many :contractor_settlement_line_revenue_inputs, dependent: :restrict_with_exception
  has_many :contractor_settlement_lines, through: :contractor_settlement_line_revenue_inputs

  SOURCE_TYPES = %w[manual imported_csv adjustment reversal].freeze

  SOURCE_TYPE_LABELS = {
    "manual" => "Manual",
    "imported_csv" => "Imported CSV",
    "adjustment" => "Adjustment",
    "reversal" => "Reversal"
  }.freeze

  def self.source_type_options_for_select
    SOURCE_TYPES.map { |t| [ SOURCE_TYPE_LABELS[t] || t.humanize, t ] }
  end

  validates :period_start_on, :period_end_on, presence: true
  validates :commissionable_revenue_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validate :engagement_in_agency
  validate :pay_period_matches_employee_contractor_rules

  private

  def engagement_in_agency
    return if engagement.blank? || agency_id.blank?
    return if engagement.agency_id == agency_id

    errors.add(:agency_id, "must match engagement")
  end

  def pay_period_matches_employee_contractor_rules
    return if engagement.blank?

    if engagement.relationship_type == "employee"
      errors.add(:pay_period_id, "is required for employee engagements") if pay_period_id.blank?
    end
    # Contractors: pay_period optional; period bounds still required
  end
end

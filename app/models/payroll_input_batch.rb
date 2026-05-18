# frozen_string_literal: true

class PayrollInputBatch < ApplicationRecord
  STATUSES = %w[draft finalized exported reversed].freeze

  belongs_to :agency
  belongs_to :pay_period
  belongs_to :payroll_export, optional: true
  belongs_to :finalized_by, class_name: "User", optional: true
  belongs_to :exported_by, class_name: "User", optional: true
  belongs_to :reversed_by, class_name: "User", optional: true
  belongs_to :supersedes_batch, class_name: "PayrollInputBatch", optional: true
  belongs_to :superseded_by_batch, class_name: "PayrollInputBatch", optional: true, foreign_key: :superseded_by_batch_id

  has_many :payroll_input_rows, dependent: :destroy
  has_many :payroll_input_adjustments, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reference_number, presence: true
  validates :reference_sequence, numericality: { only_integer: true, greater_than: 0 }
  validate :agency_matches_pay_period
  validate :at_most_one_draft_per_pay_period, if: :draft?

  scope :for_agency, ->(agency_id) { where(agency_id:) }
  scope :drafts, -> { where(status: "draft") }

  before_validation :assign_reference_defaults, on: :create

  def draft?
    status == "draft"
  end

  def finalized?
    status == "finalized"
  end

  def exported?
    status == "exported"
  end

  def reversed?
    status == "reversed"
  end

  private

  def agency_matches_pay_period
    return if agency_id.blank? || pay_period_id.blank?
    return if agency_id == pay_period.agency_id

    errors.add(:pay_period_id, "must belong to the same agency")
  end

  def at_most_one_draft_per_pay_period
    scope = PayrollInputBatch.where(agency_id:, pay_period_id:, status: "draft")
    scope = scope.where.not(id:) if persisted?
    return unless scope.exists?

    errors.add(:base, "An active draft payroll input batch already exists for this pay period.")
  end

  def assign_reference_defaults
    self.reference_sequence ||= next_reference_sequence
    self.reference_number ||= "PIB-#{pay_period_id}-#{reference_sequence.to_s.rjust(4, '0')}"
  end

  def next_reference_sequence
    PayrollInputBatch.where(pay_period_id:).maximum(:reference_sequence).to_i + 1
  end
end

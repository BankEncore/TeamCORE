# frozen_string_literal: true

class PayPeriod < ApplicationRecord
  STATUSES = %w[open closed].freeze

  belongs_to :agency
  belongs_to :closed_by, class_name: "User", optional: true
  has_many :revenue_inputs, dependent: :restrict_with_exception
  has_many :commission_calculations, dependent: :restrict_with_exception
  has_many :payroll_exports, dependent: :restrict_with_exception
  has_many :payroll_input_batches, dependent: :restrict_with_exception
  has_many :pay_period_closure_events, dependent: :restrict_with_exception

  validates :start_on, :end_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :payroll_frequency, presence: true
  validate :end_on_after_start
  validate :no_overlapping_sibling_periods
  validate :immutable_dates_when_open_but_restrict_metadata_only_via_controller

  before_update :abort_if_closed

  scope :open_periods, -> { where(status: "open") }
  scope :closed_periods, -> { where(status: "closed") }

  def closed?
    status == "closed"
  end

  def open?
    status == "open"
  end

  private

  def end_on_after_start
    return if start_on.blank? || end_on.blank?
    return if end_on >= start_on

    errors.add(:end_on, "must be on or after start_on")
  end

  # Dates must never change once persisted — boundaries come from generation (Phase 5 payroll rails).
  def immutable_dates_when_open_but_restrict_metadata_only_via_controller
    return unless persisted?
    return unless start_on_changed? || end_on_changed?

    errors.add(:base, "Pay period date boundaries cannot be changed")
  end

  def no_overlapping_sibling_periods
    return if start_on.blank? || end_on.blank? || agency_id.blank?

    scope = PayPeriod.where(agency_id:).where.not(id: id || 0)
    overlaps = scope.where("pay_periods.start_on <= ? AND pay_periods.end_on >= ?", end_on, start_on)
    errors.add(:base, "Pay period overlaps an existing period for this agency") if overlaps.exists?
  end

  def abort_if_closed
    return unless status_was == "closed"

    errors.add(:base, "Closed pay periods cannot be changed.")
    throw(:abort)
  end
end

# frozen_string_literal: true

class AgencyPayrollConfiguration < ApplicationRecord
  FREQUENCIES = %w[weekly biweekly semimonthly monthly].freeze

  belongs_to :agency

  validates :payroll_frequency, presence: true, inclusion: { in: FREQUENCIES }
  validates :workweek_starts_on, inclusion: { in: 0..6 }
  validates :weekly_overtime_threshold_hours, numericality: { greater_than: 0 }
  validate :payroll_timezone_must_be_recognized
  validate :pay_schedule_anchor_on_must_be_present_when_required

  normalizes :payroll_timezone, with: ->(tz) { tz.to_s.strip }

  private

  def payroll_timezone_must_be_recognized
    return if payroll_timezone.blank?

    TZInfo::Timezone.get(payroll_timezone)
  rescue TZInfo::InvalidTimezoneIdentifier, TZInfo::LocationConflictError
    errors.add(:payroll_timezone, "is not a valid IANA timezone")
  end

  def pay_schedule_anchor_on_must_be_present_when_required
    return if payroll_frequency.blank?
    return if payroll_frequency == "semimonthly"

    errors.add(:pay_schedule_anchor_on, "must be set") if pay_schedule_anchor_on.blank?
  end
end

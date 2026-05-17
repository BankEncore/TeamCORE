# frozen_string_literal: true

class LeaveRequest < ApplicationRecord
  STATUSES = %w[draft submitted approved rejected cancelled].freeze

  belongs_to :engagement, inverse_of: :leave_requests
  belongs_to :leave_type, inverse_of: :leave_requests
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :leave_request_days, inverse_of: :leave_request, dependent: :destroy
  has_many :leave_request_approval_events, inverse_of: :leave_request, dependent: :restrict_with_exception

  accepts_nested_attributes_for :leave_request_days,
    allow_destroy: true,
    reject_if: proc { |attrs| attrs["leave_date"].blank? && attrs[:leave_date].blank? }

  validates :status, inclusion: { in: STATUSES }
  validate :engagement_must_be_leave_eligible
  validate :leave_type_matches_agency
  before_validation :sync_bounds_from_days

  scope :submitted_queue, -> { where(status: "submitted") }

  def total_scheduled_hours
    leave_request_days.reject(&:marked_for_destruction?).sum { |d| BigDecimal(d.hours.to_s) }
  end

  private

  def engagement_must_be_leave_eligible
    return if engagement.blank?

    unless engagement.active_for_leave?
      errors.add(:engagement_id, "must be an active employee engagement eligible for leave")
    end
  end

  def leave_type_matches_agency
    return if engagement.blank? || leave_type.blank?

    unless leave_type.agency_id == engagement.agency_id
      errors.add(:leave_type_id, "must belong to the same agency as the engagement")
    end
  end

  def sync_bounds_from_days
    rows = leave_request_days.reject(&:marked_for_destruction?)
    return if rows.empty?

    dates = rows.map(&:leave_date).compact
    return if dates.empty?

    self.start_on = dates.min
    self.end_on = dates.max
  end
end

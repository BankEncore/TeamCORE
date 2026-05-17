# frozen_string_literal: true

class WeeklyTimesheet < ApplicationRecord
  STATUSES = %w[draft submitted approved rejected].freeze

  belongs_to :engagement, inverse_of: :weekly_timesheets
  belongs_to :approved_by, class_name: "User", optional: true, inverse_of: :weekly_timesheets_approved
  belongs_to :rejected_by, class_name: "User", optional: true, inverse_of: :weekly_timesheets_rejected

  validates :week_start_on, :week_end_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :week_end_matches_start
  validate :engagement_must_track_time

  scope :for_pay_period_overlap, lambda { |pay_period|
    where("weekly_timesheets.week_end_on >= ? AND weekly_timesheets.week_start_on <= ?", pay_period.start_on, pay_period.end_on)
  }

  scope :approved, -> { where(status: "approved") }

  private

  def week_end_matches_start
    return if week_start_on.blank? || week_end_on.blank?
    return if week_end_on == week_start_on + 6.days

    errors.add(:week_end_on, "must be six days after week_start_on")
  end

  def engagement_must_track_time
    return if engagement.blank?

    unless engagement.active_for_time_tracking?
      errors.add(:engagement_id, "must be an active employee engagement eligible for time tracking")
    end
  end
end

# frozen_string_literal: true

class DailyWorkedHour < ApplicationRecord
  enum :source, { employee: 0, supervisor: 1, admin: 2, imported: 3 }, validate: true

  belongs_to :engagement, inverse_of: :daily_worked_hours

  validates :work_date, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 0 }
  validate :engagement_must_track_time

  private

  def engagement_must_track_time
    return if engagement.blank?

    unless engagement.active_for_time_tracking?
      errors.add(:engagement_id, "must be an active employee engagement eligible for time tracking")
    end
  end
end

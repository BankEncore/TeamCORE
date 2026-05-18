# frozen_string_literal: true

class WeeklyTimesheetApprovalEvent < ApplicationRecord
  EVENT_TYPES = %w[approved sent_back returned_for_correction reopened].freeze

  attribute :metadata, :json, default: -> { {} }

  belongs_to :weekly_timesheet, inverse_of: :weekly_timesheet_approval_events
  belongs_to :actor, class_name: "User", inverse_of: :weekly_timesheet_approval_events_as_actor

  validates :occurred_at, :transition_from, :transition_to, :event_type, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  def metadata_hash
    raw = metadata
    return {}.with_indifferent_access if raw.blank?

    (raw.is_a?(Hash) ? raw : JSON.parse(raw.to_s)).with_indifferent_access
  rescue JSON::ParserError
    {}.with_indifferent_access
  end
end

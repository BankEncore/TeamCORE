# frozen_string_literal: true

class LeaveRequestApprovalEvent < ApplicationRecord
  EVENT_TYPES = %w[submitted approved rejected cancelled reopened].freeze

  attribute :metadata, :json, default: -> { {} }

  belongs_to :leave_request, inverse_of: :leave_request_approval_events
  belongs_to :actor, class_name: "User", inverse_of: :leave_request_approval_events_as_actor

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

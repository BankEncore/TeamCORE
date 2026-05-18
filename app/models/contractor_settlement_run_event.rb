# frozen_string_literal: true

class ContractorSettlementRunEvent < ApplicationRecord
  belongs_to :contractor_settlement_run
  belongs_to :actor, class_name: "User", optional: true

  EVENT_TYPES = %w[created calculated finalized voided payment_recorded draft_exported final_exported].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
end

# frozen_string_literal: true

class PayPeriodClosureEvent < ApplicationRecord
  EVENT_TYPES = %w[closed override_closed reopened].freeze

  SOURCES = {
    admin_manual: "admin_manual",
    payroll_final_export: "payroll_final_export"
  }.freeze

  belongs_to :pay_period
  belongs_to :payroll_input_batch, optional: true
  belongs_to :actor, class_name: "User"

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES.values }
  validates :override_validation, inclusion: { in: [ true, false ] }
end

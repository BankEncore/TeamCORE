# frozen_string_literal: true

module LifecycleStatusable
  extend ActiveSupport::Concern

  STATUSES = %w[active inactive archived].freeze

  included do
    validates :status, presence: true, inclusion: { in: STATUSES }
    before_validation :set_default_status, on: :create

    scope :active, -> { where(status: "active") }
    scope :inactive, -> { where(status: "inactive") }
    scope :archived, -> { where(status: "archived") }
  end

  def active?
    status == "active"
  end

  def inactive?
    status == "inactive"
  end

  def archived?
    status == "archived"
  end

  private

  def set_default_status
    self.status = "active" if status.blank?
  end
end

# frozen_string_literal: true

class PartyContactMethod < ApplicationRecord
  include LifecycleStatusable

  CONTACT_TYPES = %w[email phone address website other].freeze

  belongs_to :party, inverse_of: :party_contact_methods

  validates :party, presence: true
  validates :contact_type, presence: true, inclusion: { in: CONTACT_TYPES }
  validates :value, presence: true
  validate :single_active_primary_per_contact_type

  private

  def single_active_primary_per_contact_type
    return unless is_primary?
    return unless status == "active"

    dup = PartyContactMethod.where(party_id:, contact_type:, is_primary: true, status: "active")
    dup = dup.where.not(id:) if persisted?

    errors.add(:is_primary, "already have an active primary for this contact type") if dup.exists?
  end
end

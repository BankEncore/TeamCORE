# frozen_string_literal: true

class OrganizationProfile < ApplicationRecord
  ORGANIZATION_KINDS = %w[
    contractor_organization
    vendor
    agency_partner
    client
    other
  ].freeze

  belongs_to :party, inverse_of: :organization_profile

  validates :party, presence: true
  validates :organization_kind, presence: true, inclusion: { in: ORGANIZATION_KINDS }
  validate :party_must_be_organization

  after_save :maybe_fill_party_display_name

  private

  def party_must_be_organization
    return if party.blank?

    errors.add(:party, :invalid) unless party.organization?
  end

  def maybe_fill_party_display_name
    return if party.blank? || party.display_name.present?

    cand = trade_name.presence || legal_name.presence
    return if cand.blank?

    party.update_columns(display_name: cand, updated_at: Time.current)
  end
end

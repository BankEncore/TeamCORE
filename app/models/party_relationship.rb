# frozen_string_literal: true

class PartyRelationship < ApplicationRecord
  include LifecycleStatusable

  RELATIONSHIP_TYPES = %w[
    primary_contact
    secondary_contact
    subcontractor
    subcontractor_contact
    representative
    owner
    related_contact
    other
  ].freeze

  belongs_to :agency
  belongs_to :source_party, class_name: "Party", inverse_of: :outgoing_party_relationships
  belongs_to :target_party, class_name: "Party", inverse_of: :incoming_party_relationships

  validates :agency_id, :source_party_id, :target_party_id, presence: true
  validates :relationship_type, presence: true, inclusion: { in: RELATIONSHIP_TYPES }
  validate :no_self_reference
  validate :parties_share_agency
  validate :primary_contact_party_kinds
  validate :single_active_primary_contact_for_source

  def currently_effective_on?(check_date = Date.current)
    return false unless active?

    (effective_start_date.nil? || effective_start_date <= check_date) &&
      (effective_end_date.nil? || effective_end_date >= check_date)
  end

  private

  def no_self_reference
    return if source_party_id.blank? || target_party_id.blank?
    return if source_party_id != target_party_id

    errors.add(:target_party_id, "cannot equal source party")
  end

  def parties_share_agency
    return if source_party.blank? || target_party.blank? || agency.blank?
    unless source_party.agency_id == agency_id && target_party.agency_id == agency_id
      errors.add(:base, "source and target must belong to the relationship agency")
    end
  end

  def primary_contact_party_kinds
    return unless relationship_type == "primary_contact"

    unless source_party&.organization?
      errors.add(:source_party, "must be an organization-type party for primary_contact")
    end
    return if target_party&.person?

    errors.add(:target_party, "must be a person-type party for primary_contact")
  end

  def single_active_primary_contact_for_source
    return unless relationship_type == "primary_contact"
    return unless status == "active"
    return unless currently_effective_on?(Date.current)

    others = PartyRelationship.where(
      source_party_id:,
      relationship_type: "primary_contact",
      status: "active"
    )
    others = others.where.not(id:) if persisted?

    overlaps = others.any? { |o| o.currently_effective_on?(Date.current) }
    errors.add(:base, "only one active primary contact per contractor organization at a time") if overlaps
  end
end

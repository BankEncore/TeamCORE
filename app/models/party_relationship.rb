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
  validate :subcontractor_effective_date_order, if: :subcontractor?
  validate :subcontractor_source_eligible, if: :subcontractor?
  validate :subcontractor_no_overlapping_active_pair, if: :subcontractor?

  def currently_effective_on?(check_date = Date.current)
    return false unless active?

    (effective_start_date.nil? || effective_start_date <= check_date) &&
      (effective_end_date.nil? || effective_end_date >= check_date)
  end

  def subcontractor?
    relationship_type == "subcontractor"
  end

  # Person source that qualified via IC must still be contractor-capable on write; history rows stay persisted.
  def subcontractor_person_source_stale_for_display?
    return false unless subcontractor?
    return false unless source_party&.person?

    !source_party.subcontractor_source_contractor_capable_for_agency?(agency)
  end

  def promotion_eligible?(check_date = Date.current)
    subcontractor? && active? && currently_effective_on?(check_date) &&
      source_party&.subcontractor_source_contractor_capable_for_agency?(agency) &&
      target_party&.identity_complete?
  end

  private

  def date_bounds_overlap?(start_a, end_a, start_b, end_b)
    s1 = start_a || Date.new(1, 1, 1)
    e1 = end_a || Date.new(9999, 12, 31)
    s2 = start_b || Date.new(1, 1, 1)
    e2 = end_b || Date.new(9999, 12, 31)
    s1 <= e2 && s2 <= e1
  end

  def subcontractor_effective_date_order
    return if effective_start_date.blank? || effective_end_date.blank?
    return if effective_end_date >= effective_start_date

    errors.add(:effective_end_date, "must be on or after effective start date")
  end

  def subcontractor_source_eligible
    return if source_party.blank? || agency.blank?

    unless source_party.subcontractor_source_contractor_capable_for_agency?(agency)
      errors.add(:source_party, "must be a contractor organization or a person with an active individual contractor engagement for this agency")
    end
  end

  def subcontractor_no_overlapping_active_pair
    return unless active?

    others = PartyRelationship.where(
      agency_id: agency_id,
      source_party_id: source_party_id,
      target_party_id: target_party_id,
      relationship_type: "subcontractor",
      status: "active"
    )
    others = others.where.not(id: id) if persisted?

    conflict = others.any? do |o|
      date_bounds_overlap?(
        effective_start_date, effective_end_date,
        o.effective_start_date, o.effective_end_date
      )
    end
    return unless conflict

    errors.add(
      :base,
      "another active subcontractor relationship for this source and target overlaps these effective dates"
    )
  end

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

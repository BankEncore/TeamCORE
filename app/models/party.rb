# frozen_string_literal: true

class Party < ApplicationRecord
  include LifecycleStatusable

  PARTY_TYPES = %w[person organization].freeze

  belongs_to :agency
  has_one :person_profile, inverse_of: :party, dependent: :restrict_with_exception
  has_one :organization_profile, inverse_of: :party, dependent: :restrict_with_exception
  has_many :party_contact_methods, inverse_of: :party, dependent: :restrict_with_exception
  has_many :team_members, inverse_of: :party, dependent: :restrict_with_exception
  has_many(
    :outgoing_party_relationships,
    class_name: "PartyRelationship",
    foreign_key: :source_party_id,
    inverse_of: :source_party,
    dependent: :restrict_with_exception
  )
  has_many(
    :incoming_party_relationships,
    class_name: "PartyRelationship",
    foreign_key: :target_party_id,
    inverse_of: :target_party,
    dependent: :restrict_with_exception
  )

  accepts_nested_attributes_for :person_profile, update_only: true
  accepts_nested_attributes_for :organization_profile, update_only: true

  validates :party_type, presence: true, inclusion: { in: PARTY_TYPES }
  validates :agency, presence: true
  validate :persisted_profiles_match_party_type
  validate :display_name_required_when_identity_complete

  before_validation :default_display_name_from_profile_if_blank

  def person?
    party_type == "person"
  end

  def organization?
    party_type == "organization"
  end

  def identity_complete?
    if person?
      person_profile.present?
    elsif organization?
      organization_profile.present?
    else
      false
    end
  end

  # Phase 1 subcontractor source: contractor org party, or person with same-agency active IC engagement.
  def subcontractor_source_contractor_capable_for_agency?(agency_or_id)
    aid = agency_or_id.is_a?(Agency) ? agency_or_id.id : agency_or_id.to_i
    return false unless aid == agency_id

    if organization?
      organization_profile&.organization_kind == "contractor_organization"
    elsif person?
      Engagement.joins(:team_member).exists?(
        agency_id: aid,
        relationship_type: "individual_contractor",
        status: "active",
        team_members: { party_id: id }
      )
    else
      false
    end
  end

  private

  def default_display_name_from_profile_if_blank
    return if display_name.present?

    if person?
      p = person_profile
      return unless p

      self.display_name = PersonProfile.compose_display_candidate(p)

    elsif organization?
      o = organization_profile
      return unless o

      self.display_name = o.trade_name.presence || o.legal_name.presence
    end
  end

  def persisted_profiles_match_party_type
    return unless persisted?

    if person? && OrganizationProfile.exists?(party_id: id)
      errors.add(:base, "person party cannot have an organization profile")
    end
    return unless organization? && PersonProfile.exists?(party_id: id)

    errors.add(:base, "organization party cannot have a person profile")
  end

  def display_name_required_when_identity_complete
    return unless identity_complete?

    errors.add(:display_name, :blank) if display_name.blank?
  end
end

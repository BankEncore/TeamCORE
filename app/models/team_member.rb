# frozen_string_literal: true

class TeamMember < ApplicationRecord
  include LifecycleStatusable
  include NormalizesTeamMemberNumber

  belongs_to :agency
  belongs_to :party, inverse_of: :team_members
  has_many :engagements, inverse_of: :team_member, dependent: :restrict_with_exception
  has_many :document_records, inverse_of: :team_member, dependent: :restrict_with_exception

  validates :agency_id, presence: true
  validates :party_id, presence: true
  validates :party_id, uniqueness: { scope: :agency_id }
  validates :team_member_number, uniqueness: { scope: :agency_id, allow_blank: true }
  validate :party_belongs_to_same_agency
  validate :party_ready_for_team_member

  private

  def party_belongs_to_same_agency
    return if party.blank? || agency.blank?
    return if party.agency_id == agency_id

    errors.add(:party, :invalid)
  end

  def party_ready_for_team_member
    return if party.blank?

    unless party.identity_complete?
      errors.add(:party, "must have a complete identity (matching profile) before team membership")
      return
    end

    return if party.display_name.present?

    errors.add(:party, "must have a display name before team membership")
  end
end

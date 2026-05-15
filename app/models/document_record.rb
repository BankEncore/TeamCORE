# frozen_string_literal: true

class DocumentRecord < ApplicationRecord
  STATUSES = %w[submitted verified rejected voided].freeze

  belongs_to :agency
  belongs_to :document_type, inverse_of: :document_records
  belongs_to :team_member, optional: true
  belongs_to :engagement, optional: true
  belongs_to :party, optional: true
  belongs_to :verified_by, class_name: "User", optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :require_team_member_or_engagement
  validate :agency_aligns_with_belongs
  validate :engagement_team_member_consistency
  validate :validate_fields_for_status

  before_validation :ensure_agency_from_members
  before_validation :sync_team_member_from_engagement

  private

  def sync_team_member_from_engagement
    return if engagement_id.blank?

    eng = engagement.presence || Engagement.find_by(id: engagement_id)
    return if eng.blank?

    self.team_member_id = eng.team_member_id
    self.agency_id = eng.agency_id if agency_id.blank?
  end

  def ensure_agency_from_members
    return if agency_id.present?

    if team_member.present?
      self.agency_id = team_member.agency_id
    elsif team_member_id.present?
      tm = TeamMember.find_by(id: team_member_id)
      self.agency_id = tm.agency_id if tm
    end
  end

  def require_team_member_or_engagement
    return if team_member_id.present? || engagement_id.present?

    errors.add(:base, "must attach to a team member and/or an engagement")
  end

  def agency_aligns_with_belongs
    if engagement.present? && agency_id.present? && engagement.agency_id != agency_id
      errors.add(:agency_id, "must match engagement's agency")
    end

    if team_member.present? && agency_id.present? && team_member.agency_id != agency_id
      errors.add(:agency_id, "must match team member's agency")
    end
  end

  def engagement_team_member_consistency
    return if engagement.blank? || team_member_id.blank?

    return if engagement.team_member_id == team_member_id

    errors.add(:team_member_id, "must match engagement's team member")
  end

  def validate_fields_for_status
    case status
    when "submitted"
      errors.add(:submitted_on, :blank) if submitted_on.blank?
    when "verified"
      errors.add(:verified_by_id, :blank) if verified_by_id.blank?
      errors.add(:verified_on, :blank) if verified_on.blank?
    when "rejected"
      errors.add(:verified_by_id, :blank) if verified_by_id.blank?
      errors.add(:verified_on, :blank) if verified_on.blank?
      errors.add(:rejection_reason, :blank) if rejection_reason.blank?
    end
  end
end

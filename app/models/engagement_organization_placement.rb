# frozen_string_literal: true

class EngagementOrganizationPlacement < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement, inverse_of: :engagement_organization_placements
  belongs_to :department, optional: true
  belongs_to :location, optional: true
  belongs_to :team, optional: true

  validates :agency_id, :engagement_id, :effective_start_on, presence: true
  validate :agency_matches_engagement
  validate :org_rows_match_placement_agency
  validate :org_rows_active_when_present
  validate :effective_interval_must_not_overlap_siblings

  before_validation :sync_agency_from_engagement

  def self.date_intervals_overlap?(start1, end1, start2, end2)
    return false if start1.blank? || start2.blank?

    !((end1 && start2 > end1) || (end2 && start1 > end2))
  end

  private

  def sync_agency_from_engagement
    self.agency_id = engagement.agency_id if engagement.present?
  end

  def agency_matches_engagement
    return if engagement.blank? || agency_id.blank?
    return if agency_id == engagement.agency_id

    errors.add(:agency_id, "must match engagement's agency")
  end

  def org_rows_match_placement_agency
    return if agency_id.blank?

    if department.present? && department.agency_id != agency_id
      errors.add(:department_id, :invalid)
    end
    errors.add(:location_id, :invalid) if location.present? && location.agency_id != agency_id
    return unless team.present?
    return if team.agency_id == agency_id

    errors.add(:team_id, :invalid)
  end

  def org_rows_active_when_present
    errors.add(:department, "must be active for new placements") if department.present? && !department.active?

    errors.add(:location, "must be active for new placements") if location.present? && !location.active?

    errors.add(:team, "must be active for new placements") if team.present? && !team.active?
  end

  def effective_interval_must_not_overlap_siblings
    return unless engagement_id && effective_start_on

    others = EngagementOrganizationPlacement.where(engagement_id:)
    others = others.where.not(id:) if persisted?

    overlap = others.any? do |o|
      EngagementOrganizationPlacement.date_intervals_overlap?(
        effective_start_on,
        effective_end_on,
        o.effective_start_on,
        o.effective_end_on
      )
    end

    errors.add(:base, "placement overlaps an existing placement interval") if overlap
  end
end

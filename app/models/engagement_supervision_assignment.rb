# frozen_string_literal: true

class EngagementSupervisionAssignment < ApplicationRecord
  SUPERVISION_REL_TYPES = %w[primary_reports_to].freeze

  belongs_to :agency
  belongs_to :engagement, inverse_of: :engagement_supervision_assignments
  belongs_to :supervisor_engagement,
    class_name: "Engagement",
    inverse_of: :supervising_assignments

  validates :agency_id, :engagement_id, :supervisor_engagement_id, :effective_start_on, presence: true
  validates :relationship_type,
    inclusion: { in: SUPERVISION_REL_TYPES },
    presence: true
  validate :agencies_aligned
  validate :must_not_supervise_self
  validate :supervisor_eligibility_for_mvp
  validate :effective_interval_must_not_overlap_siblings

  before_validation :sync_agency_from_supervised_engagement

  def self.date_intervals_overlap?(start1, end1, start2, end2)
    EngagementOrganizationPlacement.date_intervals_overlap?(start1, end1, start2, end2)
  end

  private

  def sync_agency_from_supervised_engagement
    self.agency_id = engagement.agency_id if engagement.present?
  end

  def agencies_aligned
    return if engagement.blank?

    if agency_id != engagement.agency_id
      errors.add(:agency_id, "must match supervised engagement's agency")
    end

    return if supervisor_engagement.blank?

    return if supervisor_engagement.agency_id == engagement.agency_id

    errors.add(:supervisor_engagement_id, "must belong to same agency")
  end

  def must_not_supervise_self
    return if engagement_id.blank? || supervisor_engagement_id.blank?
    return if engagement_id != supervisor_engagement_id

    errors.add(:supervisor_engagement_id, "cannot supervise its own engagement")
  end

  def supervisor_eligibility_for_mvp
    return if supervisor_engagement.blank?

    unless supervisor_engagement.status == "active"
      errors.add(:supervisor_engagement_id, "supervisor engagement must be active")
    end
    if supervisor_engagement.relationship_type == "contractor_organization"
      errors.add(:supervisor_engagement_id, "contractor organization engagement cannot supervise in MVP")
      return
    end
    return if supervisor_engagement.relationship_type == "employee"

    errors.add(:supervisor_engagement_id, "MVP requires supervisor to be an employee engagement")
  end

  def effective_interval_must_not_overlap_siblings
    return unless engagement_id && supervisor_engagement_id && effective_start_on

    others = EngagementSupervisionAssignment.where(engagement_id:)
      .where(relationship_type: relationship_type.presence || "primary_reports_to")
    others = others.where.not(id:) if persisted?

    overlap = others.any? do |o|
      EngagementSupervisionAssignment.date_intervals_overlap?(
        effective_start_on,
        effective_end_on,
        o.effective_start_on,
        o.effective_end_on
      )
    end

    errors.add(:base, "supervision interval overlaps an existing assignment") if overlap
  end
end

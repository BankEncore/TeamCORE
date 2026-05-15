# frozen_string_literal: true

class Engagement < ApplicationRecord
  include EngagementWorkflowEligibility

  RELATIONSHIP_TYPES = %w[
    employee
    individual_contractor
    contractor_organization
    subcontractor
  ].freeze

  STATUSES = %w[
    draft
    pending
    active
    suspended
    ended
    terminated
    cancelled
  ].freeze

  TERMINAL_STATUSES = %w[ended terminated cancelled].freeze

  ALLOWED_STATUS_TRANSITIONS = {
    "draft" => %w[pending cancelled],
    "pending" => %w[active cancelled],
    "active" => %w[suspended ended terminated],
    "suspended" => %w[active ended terminated]
  }.freeze

  belongs_to :agency
  belongs_to :team_member, inverse_of: :engagements
  has_many :engagement_organization_placements,
    inverse_of: :engagement,
    dependent: :restrict_with_exception
  has_many :engagement_supervision_assignments,
    inverse_of: :engagement,
    dependent: :restrict_with_exception
  has_many :supervising_assignments,
    class_name: "EngagementSupervisionAssignment",
    foreign_key: :supervisor_engagement_id,
    inverse_of: :supervisor_engagement,
    dependent: :restrict_with_exception
  has_many :document_records, inverse_of: :engagement, dependent: :restrict_with_exception

  validates :relationship_type, presence: true, inclusion: { in: RELATIONSHIP_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :agency_matches_team_member
  validate :relationship_type_matches_party
  validate :enforce_business_dates_for_status
  validate :enforce_expected_end_on_order
  validate :enforce_no_terminal_status_change
  validate :enforce_mvp_status_transition
  validate :at_most_one_active_per_relationship_tuple

  before_validation :assign_default_status

  private

  def assign_default_status
    self.status = "draft" if new_record? && status.blank?
  end

  def agency_matches_team_member
    return if team_member.blank? || agency_id.blank?

    return if team_member.agency_id == agency_id

    errors.add(:agency_id, "must match team member's agency")
  end

  def relationship_type_matches_party
    return if team_member.blank? || relationship_type.blank?

    party = team_member.party
    return if party.blank?

    case relationship_type
    when "employee", "individual_contractor"
      errors.add(:relationship_type, "requires a person-type party") unless party.person?
    when "contractor_organization"
      errors.add(:relationship_type, "requires an organization-type party") unless party.organization?
    when "subcontractor"
      # person or organization permitted
    end
  end

  def enforce_business_dates_for_status
    return if status.blank?

    case status
    when "draft", "pending"
      errors.add(:end_on, "must be blank") if end_on.present?
    when "active", "suspended"
      errors.add(:start_on, :blank) if start_on.blank?
      errors.add(:end_on, "must be blank") if end_on.present?
    when "ended", "terminated"
      errors.add(:start_on, :blank) if start_on.blank?
      errors.add(:end_on, :blank) if end_on.blank?
    when "cancelled"
      # Optional start_on/end_on — see TC-03-D07; MVP leaves end_on unset when never effective
    end
  end

  def enforce_expected_end_on_order
    return if expected_end_on.blank? || start_on.blank?
    return if expected_end_on >= start_on

    errors.add(:expected_end_on, "must be on or after start_on")
  end

  def enforce_no_terminal_status_change
    return unless persisted? && status_changed?
    return unless TERMINAL_STATUSES.include?(status_was)

    errors.add(:status, "cannot change from a terminal status")
  end

  def enforce_mvp_status_transition
    return unless persisted? && status_changed?
    return if errors[:status].present?

    from = status_was
    allowed = ALLOWED_STATUS_TRANSITIONS[from]

    errors.add(:status, "no transitions defined from #{from}") unless allowed&.include?(status)
  end

  def at_most_one_active_per_relationship_tuple
    return unless agency_id && team_member_id && relationship_type
    return unless status == "active"

    scope = Engagement.where(
      agency_id:,
      team_member_id:,
      relationship_type:,
      status: "active"
    )
    scope = scope.where.not(id:) if persisted?

    errors.add(:base, "already has an active engagement for this relationship type") if scope.exists?
  end
end

# frozen_string_literal: true

class CompensationPlanAssignment < ApplicationRecord
  belongs_to :agency
  belongs_to :engagement
  belongs_to :compensation_plan

  validates :effective_start_on, :snapshot_plan_name, :snapshot_plan_type, presence: true
  validate :agency_matches_engagement
  validate :agency_matches_plan
  before_validation :hydrate_snapshot_from_plan, on: :create

  scope :effective_on, ->(date) {
    where("effective_start_on <= ?", date)
      .where("effective_end_on IS NULL OR effective_end_on >= ?", date)
  }

  def self.current_for_engagement(engagement, as_of: Date.current)
    where(engagement_id: engagement.id).effective_on(as_of).order(effective_start_on: :desc).first
  end

  private

  def agency_matches_engagement
    return if engagement.blank? || agency_id.blank?
    return if engagement.agency_id == agency_id

    errors.add(:agency_id, "must match engagement's agency")
  end

  def agency_matches_plan
    return if compensation_plan.blank? || agency_id.blank?
    return if compensation_plan.agency_id == agency_id

    errors.add(:compensation_plan_id, "must belong to the same agency")
  end

  def hydrate_snapshot_from_plan
    return unless compensation_plan
    return if snapshot_plan_name.present? && snapshot_plan_type.present?

    self.snapshot_plan_name = compensation_plan.name
    self.snapshot_plan_type = compensation_plan.plan_type
    self.snapshot_commission_rate_bps = compensation_plan.default_commission_rate_bps
    self.snapshot_minimum_basis = compensation_plan.minimum_commission_basis
    self.snapshot_minimum_amount_cents = compensation_plan.minimum_commission_amount_cents
    self.snapshot_recovery_rule = compensation_plan.recovery_rule
    self.snapshot_salary_annual_cents = compensation_plan.salary_annual_cents
    self.snapshot_hourly_rate_cents = compensation_plan.hourly_rate_cents
  end
end

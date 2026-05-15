# frozen_string_literal: true

class Team < ApplicationRecord
  include LifecycleStatusable

  belongs_to :agency
  belongs_to :department, optional: true
  belongs_to :location, optional: true

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :agency_id }
  validate :department_and_location_match_agency

  private

  def department_and_location_match_agency
    if department.present? && department.agency_id != agency_id
      errors.add(:department, :invalid)
    end
    if location.present? && location.agency_id != agency_id
      errors.add(:location, :invalid)
    end
  end
end

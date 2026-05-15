# frozen_string_literal: true

class Department < ApplicationRecord
  include LifecycleStatusable

  belongs_to :agency
  belongs_to :parent_department, class_name: "Department", optional: true
  has_many :child_departments, class_name: "Department", foreign_key: :parent_department_id, inverse_of: :parent_department, dependent: :restrict_with_exception
  has_many :teams, inverse_of: :department, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :agency_id }
  validate :parent_belongs_to_same_agency
  validate :cannot_be_own_parent
  validate :parent_has_no_parent_department

  private

  def parent_belongs_to_same_agency
    return if parent_department.blank?

    errors.add(:parent_department, :invalid) if parent_department.agency_id != agency_id
  end

  def cannot_be_own_parent
    return unless parent_department_id.present? && persisted?
    return unless parent_department_id == id

    errors.add(:parent_department_id, "cannot be self")
  end

  def parent_has_no_parent_department
    return if parent_department.blank?
    return unless parent_department.parent_department_id.present?

    errors.add(:parent_department_id, "must be a top-level department within the agency (single-level hierarchy only)")
  end
end

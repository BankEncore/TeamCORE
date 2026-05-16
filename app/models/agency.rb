# frozen_string_literal: true

class Agency < ApplicationRecord
  include NormalizesCode
  include LifecycleStatusable

  has_many :departments, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :locations, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :teams, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :parties, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :team_members, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :engagements, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :user_agencies, dependent: :destroy
  has_many :users, through: :user_agencies
  has_many :document_types, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :document_requirements, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :document_records, inverse_of: :agency, dependent: :restrict_with_exception
  has_many :pay_periods, dependent: :restrict_with_exception
  has_many :compensation_plans, dependent: :restrict_with_exception
  has_many :compensation_plan_assignments, dependent: :restrict_with_exception
  has_many :revenue_inputs, dependent: :restrict_with_exception
  has_many :commission_calculations, dependent: :restrict_with_exception
  has_many :contractor_charges, dependent: :restrict_with_exception
  has_many :contractor_settlement_runs, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end

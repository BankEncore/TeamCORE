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

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end

# frozen_string_literal: true

class Location < ApplicationRecord
  include NormalizesCode
  include LifecycleStatusable

  LOCATION_TYPES = %w[office branch remote virtual client_site other].freeze

  belongs_to :agency
  has_many :teams, inverse_of: :location, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :agency_id }
  validates :location_type, presence: true, inclusion: { in: LOCATION_TYPES }
end

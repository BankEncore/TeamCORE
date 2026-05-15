# frozen_string_literal: true

class DocumentRequirement < ApplicationRecord
  REQUIREMENT_SCOPES = %w[engagement team_member].freeze
  RELATIONSHIP_TYPES = %w[any employee individual_contractor contractor_organization subcontractor].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :agency
  belongs_to :document_type, inverse_of: :document_requirements

  validates :requirement_scope, presence: true, inclusion: { in: REQUIREMENT_SCOPES }
  validates :relationship_type, presence: true, inclusion: { in: RELATIONSHIP_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :document_type_id, uniqueness: {
    scope: %i[agency_id requirement_scope relationship_type]
  }
  validate :agency_matches_document_type

  def required?
    required == true
  end

  def applies_to_engagement?(engagement)
    return false unless engagement.is_a?(Engagement)

    relationship_type == "any" || relationship_type == engagement.relationship_type
  end

  private

  def agency_matches_document_type
    return if document_type.blank? || agency_id.blank?

    return if document_type.agency_id == agency_id

    errors.add(:agency_id, "must match document type's agency")
  end
end

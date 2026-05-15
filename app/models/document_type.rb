# frozen_string_literal: true

class DocumentType < ApplicationRecord
  include NormalizesCode

  CATEGORIES = %w[
    employee_agreement
    tax_form
    contractor_agreement
    classification_support
    insurance
    certification
    other
  ].freeze

  STATUSES = %w[active inactive].freeze

  belongs_to :agency
  has_many :document_requirements, dependent: :restrict_with_exception, inverse_of: :document_type
  has_many :document_records, dependent: :restrict_with_exception, inverse_of: :document_type

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :code, presence: true, uniqueness: { scope: :agency_id }
end

# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :user_agencies, dependent: :destroy
  has_many :agencies, through: :user_agencies
  has_many :verified_document_records, class_name: "DocumentRecord", foreign_key: :verified_by_id, inverse_of: :verified_by,
    dependent: :restrict_with_exception

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
end

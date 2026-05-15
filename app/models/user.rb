# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :user_agencies, dependent: :destroy
  has_many :agencies, through: :user_agencies

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
end

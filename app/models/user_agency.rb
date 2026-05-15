# frozen_string_literal: true

class UserAgency < ApplicationRecord
  belongs_to :user
  belongs_to :agency
end

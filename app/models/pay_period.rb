# frozen_string_literal: true

class PayPeriod < ApplicationRecord
  belongs_to :agency
  has_many :revenue_inputs, dependent: :restrict_with_exception
  has_many :commission_calculations, dependent: :restrict_with_exception

  validates :start_on, :end_on, presence: true
  validate :end_on_after_start

  private

  def end_on_after_start
    return if start_on.blank? || end_on.blank?
    return if end_on >= start_on

    errors.add(:end_on, "must be on or after start_on")
  end
end

# frozen_string_literal: true

class LeaveRequestDay < ApplicationRecord
  belongs_to :leave_request, inverse_of: :leave_request_days

  validates :leave_date, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 0 }
  validates :leave_date, uniqueness: { scope: :leave_request_id }
end

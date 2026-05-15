# frozen_string_literal: true

module NormalizesCode
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_code
  end

  private

  def normalize_code
    self.code = code.to_s.strip.downcase.presence
  end
end

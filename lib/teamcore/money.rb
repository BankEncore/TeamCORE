# frozen_string_literal: true

require "bigdecimal"

module Teamcore
  # Parse/format helpers for amounts stored as integer cents in the database.
  module Money
    class InvalidAmount < ArgumentError; end

    # Accepts "12", "12.34", "$1,234.56", "  $12.50 ", etc. Returns Integer cents (rounded half-up).
    def self.cents_from_decimal_string(value)
      raise InvalidAmount, "amount is blank" if value.respond_to?(:blank?) ? value.blank? : value.to_s.strip.empty?

      s = value.to_s.strip.delete_prefix("$").gsub(",", "").gsub(/\s+/, "")
      raise InvalidAmount, "amount is not numeric" if s.empty?

      d = BigDecimal(s)
      (d * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
    rescue ArgumentError
      raise InvalidAmount, "amount is not a valid number"
    end
  end
end

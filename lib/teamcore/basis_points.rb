# frozen_string_literal: true

require "bigdecimal"

module Teamcore
  # Convert human percent input (e.g. "10", "10.5", "10.5%") to integer basis points (1 bp = 0.01%).
  module BasisPoints
    class InvalidPercent < ArgumentError; end

    def self.bps_from_percent_string(value)
      raise InvalidPercent, "percent is blank" if value.respond_to?(:blank?) ? value.blank? : value.to_s.strip.empty?

      s = value.to_s.strip.delete("%").gsub(",", "").gsub(/\s+/, "")
      raise InvalidPercent, "percent is not numeric" if s.empty?

      d = BigDecimal(s)
      (d * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
    rescue ArgumentError
      raise InvalidPercent, "percent is not a valid number"
    end
  end
end

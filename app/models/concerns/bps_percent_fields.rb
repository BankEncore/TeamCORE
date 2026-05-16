# frozen_string_literal: true

# Virtual `*_percent` form attributes (e.g. 10.00 for 10%) backed by `*_bps` integer columns.
module BpsPercentFields
  extend ActiveSupport::Concern

  class_methods do
    # @param bases [Array<Symbol>] e.g. :default_commission_rate -> default_commission_rate_bps
    def bps_percent_fields(*bases)
      bases.each do |base|
        bps_col = :"#{base}_bps"
        pct_attr = :"#{base}_percent"

        define_method(pct_attr) do
          b = public_send(bps_col)
          return "" if b.nil?

          format("%.2f", b.to_d / 100)
        end

        define_method(:"#{pct_attr}=") do |raw|
          if raw.respond_to?(:blank?) ? raw.blank? : raw.to_s.strip.empty?
            public_send(:"#{bps_col}=", nil)
            return
          end

          public_send(:"#{bps_col}=", Teamcore::BasisPoints.bps_from_percent_string(raw))
        rescue Teamcore::BasisPoints::InvalidPercent => e
          errors.add(pct_attr, e.message)
        end
      end
    end
  end
end

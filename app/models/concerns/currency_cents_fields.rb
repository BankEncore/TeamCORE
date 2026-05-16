# frozen_string_literal: true

# Exposes virtual `*_money` form fields (decimal dollars) backed by existing `*_cents` columns.
module CurrencyCentsFields
  extend ActiveSupport::Concern

  class_methods do
    # @param bases [Array<Symbol>] e.g. :minimum_commission_amount -> minimum_commission_amount_cents
    def currency_cents_fields(*bases)
      bases.each do |base|
        cents_attr = :"#{base}_cents"
        money_attr = :"#{base}_money"

        define_method(money_attr) do
          c = public_send(cents_attr)
          return "" if c.nil?

          format("%.2f", c.to_i / 100.0)
        end

        define_method(:"#{money_attr}=") do |raw|
          if raw.respond_to?(:blank?) ? raw.blank? : raw.to_s.strip.empty?
            public_send(:"#{cents_attr}=", nil)
            return
          end

          public_send(:"#{cents_attr}=", Teamcore::Money.cents_from_decimal_string(raw))
        rescue Teamcore::Money::InvalidAmount => e
          errors.add(money_attr, e.message)
        end
      end
    end
  end
end

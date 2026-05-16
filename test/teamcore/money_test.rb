# frozen_string_literal: true

require "test_helper"

class TeamcoreMoneyTest < ActiveSupport::TestCase
  test "parses decimal and currency strings to cents (half-up)" do
    assert_equal 12_345, Teamcore::Money.cents_from_decimal_string("$123.45")
    assert_equal 123_456, Teamcore::Money.cents_from_decimal_string("1,234.56")
    assert_equal 100, Teamcore::Money.cents_from_decimal_string("1")
    assert_equal 200, Teamcore::Money.cents_from_decimal_string("1.999")
  end

  test "raises on blank or invalid" do
    assert_raises(Teamcore::Money::InvalidAmount) { Teamcore::Money.cents_from_decimal_string("") }
    assert_raises(Teamcore::Money::InvalidAmount) { Teamcore::Money.cents_from_decimal_string("x") }
  end
end

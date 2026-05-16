# frozen_string_literal: true

require "test_helper"

class TeamcoreBasisPointsTest < ActiveSupport::TestCase
  test "parses percent strings to bps (half-up)" do
    assert_equal 1000, Teamcore::BasisPoints.bps_from_percent_string("10")
    assert_equal 1050, Teamcore::BasisPoints.bps_from_percent_string("10.5")
    assert_equal 1056, Teamcore::BasisPoints.bps_from_percent_string("10.555")
    assert_equal 1000, Teamcore::BasisPoints.bps_from_percent_string("10.00%")
    assert_equal 1234, Teamcore::BasisPoints.bps_from_percent_string("12.34")
  end

  test "raises on blank or invalid" do
    assert_raises(Teamcore::BasisPoints::InvalidPercent) { Teamcore::BasisPoints.bps_from_percent_string("") }
    assert_raises(Teamcore::BasisPoints::InvalidPercent) { Teamcore::BasisPoints.bps_from_percent_string("x") }
  end
end

# frozen_string_literal: true

require "test_helper"

class Team360ProfileAssemblerReadinessDelegationTest < ActiveSupport::TestCase
  test "snapshot readiness_result is exactly ReadinessEvaluator output for focused engagement" do
    agency, = p4_agency_user!
    ee = p4_active_employee!(agency, start_on: Date.new(2025, 1, 1))

    frozen_result =
      Documents::ReadinessResult.new(
        readiness_status: "not_ready",
        as_of_date: Date.new(2026, 6, 15),
        engagement_id: ee[:engagement].id,
        requirements: [],
        alerts: []
      ).freeze

    cls = Documents::ReadinessEvaluator
    original_new = cls.method(:new)
    captured_engagement = nil
    captured_as_of = nil
    cls.singleton_class.define_method(:new) do |engagement:, as_of_date: Date.current|
      captured_engagement = engagement
      captured_as_of = as_of_date
      fake = Object.new
      fake.define_singleton_method(:call) { frozen_result }
      fake
    end

    snapshot =
      Team360::ProfileAssembler.new(
        team_member: ee[:team_member],
        agency: agency,
        as_of_date: Date.new(2026, 6, 15),
        focused_engagement_id: ee[:engagement].id
      ).call

    assert_equal ee[:engagement].id, captured_engagement.id
    assert_equal Date.new(2026, 6, 15), captured_as_of
    assert_same frozen_result, snapshot.readiness_result
  ensure
    cls.singleton_class.define_method(:new, original_new)
  end
end

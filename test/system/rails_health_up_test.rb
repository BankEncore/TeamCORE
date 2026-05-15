# frozen_string_literal: true

require "application_system_test_case"

class RailsHealthUpTest < ApplicationSystemTestCase
  test "health endpoint loads" do
    visit rails_health_check_path
    assert_selector "body"
  end
end

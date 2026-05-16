require "etc"

ENV["RAILS_ENV"] ||= "test"

unless ENV.key?("PARALLEL_WORKERS")
  ENV["PARALLEL_WORKERS"] =
    case
    when ENV["CI"] == "true"
      Etc.nprocessors.to_s
    when ENV.fetch("DB_HOST", "") == "mariadb"
      # Docker Compose + forked MRI workers intermittently overwhelm / race MariaDB handshakes locally.
      "1"
    else
      Etc.nprocessors.to_s
    end
end

require_relative "../config/environment"
require "rails/test_help"

require_relative "support/phase4_test_helper"

module ActiveSupport
  class TestCase
    include Phase4TestHelper

    parallelize(workers: Integer(ENV.fetch("PARALLEL_WORKERS")))

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Phase4TestHelper
end

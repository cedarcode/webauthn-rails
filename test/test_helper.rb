# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["DATABASE_URL"] = "sqlite3::memory:"

require "minitest/autorun"
require "active_record/railtie"
require_relative "support/rails_mock"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

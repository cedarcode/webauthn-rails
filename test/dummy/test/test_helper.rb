ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# TODO: Replace this once Rails provides this helper through its authentication generator:
# https://github.com/rails/rails/blob/v8.1.0.beta1/railties/lib/rails/generators/test_unit/authentication/templates/test/test_helpers/session_test_helper.rb.tt
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    include SessionTestHelper
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

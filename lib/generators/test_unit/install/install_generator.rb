require "rails/generators/test_unit"

module TestUnit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_controller_test_files
        template "test/controllers/registrations_controller_test.rb"
        template "test/controllers/sessions_controller_test.rb"
      end

      def create_system_test_files
        template "test/system/add_credential_test.rb"
        template "test/system/registration_test.rb"
        template "test/system/sign_in_test.rb"
      end

      def create_test_helper_files
        template "test/test_helpers/virtual_authenticator_test_helper.rb"
      end

      def configure_test_helper
        inject_into_file "test/test_helper.rb", "require_relative \"test_helpers/virtual_authenticator_test_helper\"\n", after: "require \"rails/test_help\"\n"
        inject_into_class "test/test_helper.rb", "TestCase", "    include VirtualAuthenticatorTestHelper\n"
      end
    end
  end
end

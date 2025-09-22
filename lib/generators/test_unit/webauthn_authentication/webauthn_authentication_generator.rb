require "rails/generators/test_unit"

module TestUnit
  module Generators
    class WebauthnAuthenticationGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def create_controller_test_files
        template "test/controllers/passkeys_controller_test.rb"
        template "test/controllers/webauthn_sessions_controller_test.rb"
      end

      def create_system_test_files
        template "test/system/manage_webauthn_credentials_test.rb"
      end

      def create_test_helper_files
        template "test/test_helpers/virtual_authenticator_test_helper.rb"
      end
    end
  end
end

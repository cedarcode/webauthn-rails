require "rails/generators/test_unit"

module TestUnit
  module Generators
    class WebauthnAuthenticationGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def create_controller_test_files
        template "test/controllers/webauthn_credentials_controller_test.rb"
        template "test/controllers/webauthn_sessions_controller_test.rb"
      end

      def create_system_test_files
        template "test/system/manage_webauthn_credentials_test.rb"
      end

      def create_test_helper_files
        template "test/test_helpers/virtual_authenticator_test_helper.rb"
      end

      def inject_user_into_fixture
        append_to_file "test/fixtures/users.yml" do
          <<~RUBY

          user_with_strong_password:
            email_address: alice@example.com
            password_digest: <%= BCrypt::Password.create("S3cr3tP@ssw0rd!") %>
          RUBY
        end
      end
    end
  end
end

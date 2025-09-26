require "test_helper"
require "rails/generators/test_case"
require "generators/webauthn_authentication/webauthn_authentication_generator"
require "rails/generators/rails/authentication/authentication_generator"

class WebauthnAuthenticationGeneratorTest < Rails::Generators::TestCase
  tests WebauthnAuthenticationGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup do
    prepare_destination
    add_config_folder
    add_importmap
    add_routes
    add_test_helper
    add_rails_auth_user_model
    add_session_view
    add_authentication_concern
    add_gemfile
  end

  test "generates all expected files" do
    generator([ destination_root ], [ "--test-framework=test_unit" ])

    run_generator_instance

    assert_file "app/controllers/sessions_controller.rb"
    assert_file "app/controllers/webauthn_sessions_controller.rb"
    assert_file "app/controllers/passkeys_controller.rb"
    assert_file "app/controllers/second_factor_authentications_controller.rb"
    assert_file "app/controllers/second_factor_webauthn_credentials_controller.rb"

    assert_file "app/views/passkeys/new.html.erb"
    assert_file "app/views/second_factor_authentications/new.html.erb"
    assert_file "app/views/second_factor_webauthn_credentials/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "test/controllers/webauthn_sessions_controller_test.rb"
    assert_file "test/controllers/passkeys_controller_test.rb"
    assert_file "test/system/manage_webauthn_credentials_test.rb"
    assert_file "test/test_helpers/virtual_authenticator_test_helper.rb"

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_includes @rails_commands, "generate migration AddWebauthnToUsers webauthn_id:string"

    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_includes @rails_commands, "generate migration CreateWebauthnCredentials user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8} authentication_factor:integer{1}!"

    assert_file "config/routes.rb", /Rails.application.routes.draw do/
    assert_file "config/routes.rb", /resources :passkeys, only: \[\s*:new, :create, :destroy\s*\] do/

    assert_file "config/importmap.rb", /pin "@github\/webauthn-json\/browser-ponyfill"/

    assert_includes @bundle_commands, [ "add webauthn", {}, { quiet: true } ]
  end

  test "assert all files except for views are created with api flag" do
    generator([ destination_root ], [ "--api", "--test-framework=test_unit" ])

    run_generator_instance

    assert_file "app/controllers/sessions_controller.rb"
    assert_file "app/controllers/webauthn_sessions_controller.rb"
    assert_file "app/controllers/passkeys_controller.rb"
    assert_file "app/controllers/second_factor_authentications_controller.rb"
    assert_file "app/controllers/second_factor_webauthn_credentials_controller.rb"

    assert_no_file "app/views/passkeys/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "test/controllers/webauthn_sessions_controller_test.rb"
    assert_file "test/controllers/passkeys_controller_test.rb"
    assert_file "test/system/manage_webauthn_credentials_test.rb"
    assert_file "test/test_helpers/virtual_authenticator_test_helper.rb"

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_includes @rails_commands, "generate migration AddWebauthnToUsers webauthn_id:string"

    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_includes @rails_commands, "generate migration CreateWebauthnCredentials user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8} authentication_factor:integer{1}!"

    assert_file "config/routes.rb", /Rails.application.routes.draw do/
    assert_file "config/routes.rb", /resources :passkeys, only: \[\s*:new, :create, :destroy\s*\] do/

    assert_includes @bundle_commands, [ "add webauthn", {}, { quiet: true } ]
  end

  test "rails authentication generator is invoked when flag is passed" do
    generator([ destination_root ], [ "--with_rails_authentication" ])

    run_generator_stubbing_rails_auth_generator

    assert @rails_auth_generator_invoked, "Rails::Generators::AuthenticationGenerator was not invoked"
  end

  private

  def add_config_folder
    FileUtils.mkdir_p(File.join(destination_root, "config"))
  end

  def add_importmap
    FileUtils.touch(File.join(destination_root, "config", "importmap.rb"))
  end

  def add_routes
    File.write(File.join(destination_root, "config", "routes.rb"), <<~CONTENT)
      Rails.application.routes.draw do
      end
    CONTENT
  end

  def add_rails_auth_user_model
    app_folder = FileUtils.mkdir_p(File.join(destination_root, "app"))
    FileUtils.mkdir_p(File.join(app_folder, "models"))
    File.write(File.join(destination_root, "app", "models", "user.rb"), <<~CONTENT)
      class User < ApplicationRecord
        has_secure_password
        has_many :sessions, dependent: :destroy

        normalizes :email_address, with: ->(e) { e.strip.downcase }
      end
    CONTENT
  end

  def add_test_helper
    FileUtils.mkdir_p("#{destination_root}/test")
    File.write("#{destination_root}/test/test_helper.rb", <<~RUBY)
      require "rails/test_help"
      module ActiveSupport
        class TestCase
        end
      end
    RUBY
  end

  def add_gemfile
    File.write(File.join(destination_root, "Gemfile"), <<~CONTENT)
      source "https://rubygems.org"
    CONTENT
  end

  def add_session_view
    FileUtils.mkdir_p("#{destination_root}/app/views/sessions")
    File.write("#{destination_root}/app/views/sessions/new.html.erb", <<~ERB)
    ERB
  end

  def add_authentication_concern
    FileUtils.mkdir_p("#{destination_root}/app/controllers/concerns")
    File.write("#{destination_root}/app/controllers/concerns/authentication.rb", <<~RUBY)
      module Authentication
        extend ActiveSupport::Concern
      end

      def terminate_session
        Current.session.destroy
        cookies.delete(:session_id)
      end
    RUBY
  end

  def run_generator_stubbing_rails_auth_generator
    @rails_auth_generator_invoked = false
    @rails_auth_generator_stub ||= ->(invoked_generator, *args) { @rails_auth_generator_invoked ||= invoked_generator == "authentication" }

    generator.stub(:invoke, @rails_auth_generator_stub) do
      run_generator_instance
    end
  end

  def run_generator_instance
    @bundle_commands = []
    command_stub ||= ->(command, *args) { @bundle_commands << [ command, *args ] }

    @rails_commands = []
    @rails_command_stub ||= ->(command, *_) { @rails_commands << command }

    generator.stub(:bundle_command, command_stub) do
      generator.stub(:rails_command, @rails_command_stub) do
        capture(:stdout) do
          generator.invoke_all
        end
      end
    end
  end
end

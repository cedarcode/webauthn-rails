require "test_helper"
require "rails/generators/test_case"
require "generators/webauthn_authentication/webauthn_authentication_generator"
require "minitest/stub_any_instance"
require "rails/generators/rails/authentication/authentication_generator"

class WebauthnAuthenticationGeneratorTest < Rails::Generators::TestCase
  tests WebauthnAuthenticationGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup do
    prepare_destination
    add_config_folder
    add_importmap
    add_routes
    add_application_controller
    add_test_helper
    add_rails_auth_user_model
  end

  test "generates all expected files and successfully runs the Rails authentication generator" do
    generator([ destination_root ], [ "--test-framework=test_unit" ])

    Rails::Generators::AuthenticationGenerator.stub_any_instance(:invoke_all, nil) do
      run_generator_instance
    end

    assert_file "app/controllers/registrations_controller.rb"
    assert_file "app/controllers/webauthn_sessions_controller.rb"
    assert_file "app/controllers/webauthn_credentials_controller.rb"

    assert_file "app/views/webauthn_credentials/new.html.erb"
    assert_file "app/views/registrations/new.html.erb"
    assert_file "app/views/webauthn_sessions/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "test/controllers/registrations_controller_test.rb"
    assert_file "test/controllers/webauthn_sessions_controller_test.rb"
    assert_file "test/system/add_credential_test.rb"
    assert_file "test/system/registration_test.rb"
    assert_file "test/system/sign_in_test.rb"
    assert_file "test/test_helpers/virtual_authenticator_test_helper.rb"

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_includes @rails_commands, "generate migration AddWebauthnToUsers webauthn_id:string"

    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_includes @rails_commands, "generate migration CreateWebauthnCredentials user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8}"

    assert_file "config/routes.rb", /Rails.application.routes.draw do/
    assert_file "config/routes.rb", /resources :webauthn_credentials, only: \[\s*:new, :create, :destroy\s*\] do/

    assert_file "config/importmap.rb", /pin "@github\/webauthn-json\/browser-ponyfill"/
  end

  test "assert all files except for views are created with api flag" do
    generator([ destination_root ], [ "--api" ])

    Rails::Generators::AuthenticationGenerator.stub_any_instance(:invoke_all, nil) do
      run_generator_instance
    end

    assert_file "app/controllers/registrations_controller.rb"
    assert_file "app/controllers/webauthn_sessions_controller.rb"
    assert_file "app/controllers/webauthn_credentials_controller.rb"

    assert_no_file "app/views/webauthn_credentials/new.html.erb"
    assert_no_file "app/views/registrations/new.html.erb"
    assert_no_file "app/views/webauthn_sessions/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_includes @rails_commands, "generate migration AddWebauthnToUsers webauthn_id:string"

    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_includes @rails_commands, "generate migration CreateWebauthnCredentials user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8}"

    assert_file "config/routes.rb", /Rails.application.routes.draw do/
    assert_file "config/routes.rb", /resources :webauthn_credentials, only: \[\s*:new, :create, :destroy\s*\] do/
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

  def add_application_controller
    app_folder = FileUtils.mkdir_p(File.join(destination_root, "app"))
    FileUtils.mkdir_p(File.join(app_folder, "controllers"))
    File.write(File.join(destination_root, "app", "controllers", "application_controller.rb"), <<~CONTENT)
      class ApplicationController < ActionController::Base
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

  def run_generator_instance
    @rails_commands = []
    @rails_command_stub ||= ->(command, *_) { @rails_commands << command }

    generator.stub(:rails_command, @rails_command_stub) do
      capture(:stdout) do
        generator.invoke_all
      end
    end
  end
end

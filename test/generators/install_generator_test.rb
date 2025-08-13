require "test_helper"
require "rails/generators/test_case"
require "generators/webauthn/rails/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Webauthn::Rails::InstallGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup do
    prepare_destination
    add_config_folder
    add_importmap
    add_routes
    add_application_controller
  end

  test "assert all files are properly created when user model does not exist" do
    run_generator

    assert_file "app/controllers/registrations_controller.rb"
    assert_file "app/controllers/sessions_controller.rb"
    assert_file "app/controllers/webauthn_credentials_controller.rb"
    assert_file "app/controllers/concerns/authentication.rb"

    assert_file "app/controllers/application_controller.rb", /include Authentication/

    assert_file "app/views/webauthn_credentials/new.html.erb"
    assert_file "app/views/registrations/new.html.erb"
    assert_file "app/views/sessions/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_migration "db/migrate/create_users.rb", /create_table :users/
    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_migration "db/migrate/create_webauthn_credentials.rb", /create_table :webauthn_credentials/

    assert_file "config/routes.rb", /Rails.application.routes.draw do/
    assert_file "config/routes.rb", /resources :webauthn_credentials, only: \[\s*:new, :create, :destroy\s*\] do/
  end

  test "assert all files are properly created when user model already exists" do
    add_user_model

    run_generator

    assert_file "app/controllers/registrations_controller.rb"
    assert_file "app/controllers/sessions_controller.rb"
    assert_file "app/controllers/webauthn_credentials_controller.rb"
    assert_file "app/controllers/concerns/authentication.rb"

    assert_file "app/controllers/application_controller.rb", /include Authentication/

    assert_file "app/views/webauthn_credentials/new.html.erb"
    assert_file "app/views/registrations/new.html.erb"
    assert_file "app/views/sessions/new.html.erb"

    assert_file "app/javascript/controllers/webauthn_credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_migration "db/migrate/add_webauthn_to_users.rb", /change_table :users/
    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_migration "db/migrate/create_webauthn_credentials.rb", /create_table :webauthn_credentials/

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

  def add_user_model
    app_folder = FileUtils.mkdir_p(File.join(destination_root, "app"))
    FileUtils.mkdir_p(File.join(app_folder, "models"))
    File.write(File.join(destination_root, "app", "models", "user.rb"), <<~CONTENT)
      class User < ApplicationRecord
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
end

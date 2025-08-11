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
  end

  test "assert all files are properly created when user model does not exist" do
    run_generator

    assert_file "app/javascript/controllers/webauthn/rails/credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_migration "db/migrate/create_users.rb", /create_table :users/
    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_migration "db/migrate/create_webauthn_credentials.rb", /create_table :webauthn_credentials/

    assert_file "config/routes.rb", /mount Webauthn::Rails::Engine/
  end

  test "assert all files are properly created when user model already exists" do
    add_user_model

    run_generator

    assert_file "app/javascript/controllers/webauthn/rails/credentials_controller.js"

    assert_file "config/initializers/webauthn.rb", /WebAuthn.configure/

    assert_file "app/models/user.rb", /has_many :webauthn_credentials/
    assert_migration "db/migrate/add_webauthn_to_users.rb", /change_table :users/
    assert_file "app/models/webauthn_credential.rb", /belongs_to :user/
    assert_migration "db/migrate/create_webauthn_credentials.rb", /create_table :webauthn_credentials/

    assert_file "config/routes.rb", /mount Webauthn::Rails::Engine/
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
end

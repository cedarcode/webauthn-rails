require "rails/generators/base"
require "rails/generators/active_record/migration"

module Webauthn
  module Rails
    class InstallGenerator < ::Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      desc "Injects webauthn files to your application."

      def copy_controllers_and_concerns
        template "app/controllers/webauthn_credentials_controller.rb"
        template "app/controllers/registrations_controller.rb"
        template "app/controllers/sessions_controller.rb"
        template "app/controllers/concerns/authentication.rb"
      end

      def configure_application_controller
        inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Authentication\n"
      end

      def copy_views
        template "app/views/webauthn_credentials/new.html.erb.tt"
        template "app/views/registrations/new.html.erb.tt"
        template "app/views/sessions/new.html.erb.tt"
      end

      def copy_stimulus_controllers
        if using_importmap? || using_bun? || has_package_json?
          template "app/javascript/controllers/webauthn_credentials_controller.js"

          if using_bun? || has_package_json?
            run "bin/rails stimulus:manifest:update"
          end
        else
          puts "You must either be running with node (package.json) or importmap-rails (config/importmap.rb) to use this gem."
        end
      end

      def copy_initializer_file
        template "config/initializers/webauthn.rb"
      end

      def inject_webauthn_content
        @generator_class = ::Rails::Generators.find_by_namespace("active_record:model")
        if File.exist?(File.join(destination_root, "app/models/user.rb"))
          inject_user_model_content
          migration_template "db/migrate/add_webauthn_to_users.rb", "db/migrate/add_webauthn_to_users.rb"
        else
          create_user_model_and_migration
        end

        inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
          <<-RUBY.strip_heredoc.indent(2)
          resource :registration, only: [ :new, :create ] do
            post :create_options, on: :collection
          end

          resource :session, only: [ :new, :create, :destroy ] do
            post :get_options, on: :collection
          end

          resources :webauthn_credentials, only: [ :new, :create, :destroy ] do
            post :create_options, on: :collection
          end
          RUBY
        end

        create_webauthn_model_and_migration

        say ""
        say "Almost done! Now edit `config/initializers/webauthn.rb` and set the `allowed_origins` for your app.", :yellow
      end

      hook_for :test_framework

      private

      def using_bun?
        File.exist?(File.join(destination_root, "bun.config.js"))
      end

      def using_importmap?
        File.exist?(File.join(destination_root, "config/importmap.rb"))
      end

      def has_package_json?
        File.exist?(File.join(destination_root, "package.json"))
      end

      def create_user_model_and_migration
        generator_instance = @generator_class.new([
          "User",
          "username:string:uniq",
          "webauthn_id:string"
        ], {
          migration: true,
          timestamps: true,
          test_framework: false
        }, {
          destination_root: destination_root
        })
        generator_instance.invoke_all

        inject_user_model_content
      end

      def create_webauthn_model_and_migration
        generator_instance = @generator_class.new([
          "WebauthnCredential",
          "user:references",
          "external_id:string:uniq",
          "public_key:string",
          "nickname:string",
          "sign_count:integer{8}"
        ], {
          migration: true,
          test_framework: false,
          timestamps: true
        }, {
          destination_root: destination_root
        })
        generator_instance.invoke_all

        inject_webauthn_model_content

        # Modify the generated migration to add null: false to user reference
        migration_file = find_migration_file("create_webauthn_credentials")
        if migration_file
          gsub_file migration_file, "t.references :user, foreign_key: true", "t.references :user, null: false, foreign_key: true"
        end
      end

      def inject_user_model_content
        inject_into_class "app/models/user.rb", "User" do
          <<-RUBY.strip_heredoc.indent(2)
            validates :username, presence: true, uniqueness: true

            has_many :webauthn_credentials, dependent: :destroy

            after_initialize do
              self.webauthn_id ||= WebAuthn.generate_user_id
            end
          RUBY
        end
      end

      def inject_webauthn_model_content
        inject_into_class "app/models/webauthn_credential.rb", "WebauthnCredential" do
          <<-RUBY.strip_heredoc.indent(2)
            validates :external_id, :public_key, :nickname, :sign_count, presence: true
            validates :external_id, uniqueness: true
            validates :sign_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**32 - 1 }
          RUBY
        end
      end

      def find_migration_file(base_name)
        migrate_dir = File.join(destination_root, "db", "migrate")
        return nil unless Dir.exist?(migrate_dir)

        Dir.glob(File.join(migrate_dir, "*_#{base_name}.rb")).first
      end
    end
  end
end

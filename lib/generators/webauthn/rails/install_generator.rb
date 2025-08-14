require "rails/generators/base"
require "rails/generators/active_record/migration"

module Webauthn
  module Rails
    class InstallGenerator < ::Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      desc "Injects webauthn files to your application."

      def copy_controllers_and_concerns
        say "Add Webauthn controllers"
        template "app/controllers/webauthn_credentials_controller.rb"
        template "app/controllers/registrations_controller.rb"
        template "app/controllers/sessions_controller.rb"
        template "app/controllers/concerns/authentication.rb"
      end

      def configure_application_controller
        inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Authentication\n"
      end

      def copy_views
        say "Add Webauthn views"
        template "app/views/webauthn_credentials/new.html.erb.tt"
        template "app/views/registrations/new.html.erb.tt"
        template "app/views/sessions/new.html.erb.tt"
      end

      def copy_stimulus_controllers
        add_stimulus_rails_gem

        if using_importmap? || using_bun? || has_package_json?
          say "Add Webauthn Stimulus controllers"
          template "app/javascript/controllers/webauthn_credentials_controller.js"

          if using_bun? || has_package_json?
            say "Updating Stimulus manifest"
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
        if File.exist?(File.join(destination_root, "app/models/user.rb"))
          inject_into_class "app/models/user.rb", "User" do
            <<-RUBY.strip_heredoc.indent(2)
              validates :username, presence: true, uniqueness: true

              has_many :webauthn_credentials, dependent: :destroy

              after_initialize do
                self.webauthn_id ||= WebAuthn.generate_user_id
              end
            RUBY
          end

          migration_template "db/migrate/add_webauthn_to_users.rb", "db/migrate/add_webauthn_to_users.rb"
        else
          template "app/models/user.rb"
          migration_template "db/migrate/create_users.rb", "db/migrate/create_users.rb"
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

        template "app/models/webauthn_credential.rb"
        migration_template "db/migrate/create_webauthn_credentials.rb", "db/migrate/create_webauthn_credentials.rb"
      end

      def add_stimulus_rails_gem
        gemfile_path = File.join(destination_root, "Gemfile")

        unless File.exist?(gemfile_path)
          say "No Gemfile found, skipping stimulus-rails gem addition"
          return
        end

        return if File.read(gemfile_path).match?(/^\s*gem ["']stimulus-rails["']/)

        say "Add stimulus-rails gem to Gemfile"

        if File.read(gemfile_path).match?(/^\s*#\s*gem ["']stimulus-rails["']/)
          uncomment_lines gemfile_path, /gem ["']stimulus-rails["']/
        else
          gem "stimulus-rails"
        end

        Bundler.with_original_env { run "bundle install --quiet" }
      end

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
    end
  end
end

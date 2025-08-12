require "rails/generators/base"
require "rails/generators/active_record/migration"

module Webauthn
  module Rails
    class InstallGenerator < ::Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      desc "Injects webauthn files to your application."

      def copy_stimulus_controllers
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

        template "app/models/webauthn_credential.rb"
        migration_template "db/migrate/create_webauthn_credentials.rb", "db/migrate/create_webauthn_credentials.rb"
      end

      def mount_engine_routes
        inject_into_file "config/routes.rb", "  mount Webauthn::Rails::Engine => \"/webauthn-rails\"\n", before: /^end/
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

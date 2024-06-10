require 'rails/generators/base'

module Webauthn
  module Rails
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Injects webauthn files to your application."

      def copy_stimulus_controllers
        if File.exist?(File.join(destination_root, "config/importmap.rb"))
          say "Add Webauthn Stimulus controllers"
          empty_directory "app/javascript/controllers/webauthn/rails"
          template "app/javascript/controllers/webauthn/rails/add_credential_controller.js"
          template "app/javascript/controllers/webauthn/rails/new_registration_controller.js"
          template "app/javascript/controllers/webauthn/rails/new_session_controller.js"
        else
          puts "Tried to copy stimulus controllers but failed. You must be running importmap-rails (config/importmap.rb) to use this gem."
        end
      end

      def inject_js_packages
        if File.exist?(File.join(destination_root, "config/importmap.rb"))
          say %(Appending: pin "@github/webauthn-json", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js")
          append_to_file "config/importmap.rb", %(pin "@github/webauthn-json", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js"\n)

          say %(Appending: pin "webauthn-rails/credential", to: "credential.js")
          append_to_file "config/importmap.rb", %(pin "webauthn-rails/credential", to: "credential.js"\n)
        else
          puts "Tried to add js dependencies but failed. You must be running importmap-rails (config/importmap.rb) to use this gem."
        end
      end

      def copy_initializer_file
        template "config/initializers/webauthn_rails.rb"
      end

      def inject_webauthn_content
        if File.exist?(File.join(destination_root, "app/models/user.rb"))
          inject_into_class "app/models/user.rb", 'User' do
            <<-RUBY.strip_heredoc.indent(2)
              validates :username, presence: true, uniqueness: true

              has_many :credentials, dependent: :destroy, class_name: 'Webauthn::Rails::Credential'

              after_initialize do
                self.webauthn_id ||= WebAuthn.generate_user_id
              end
            RUBY
          end
        else
          say "Tried to inject webauthn into user model but couldn't find it"
        end
      end
    end
  end
end

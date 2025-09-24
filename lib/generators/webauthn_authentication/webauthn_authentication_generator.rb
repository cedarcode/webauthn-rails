require "rails/generators/base"
require "rails/generators/active_record/migration"
if Rails.version >= "8.1"
  require "rails/generators/bundle_helper"
else
  require "generators/webauthn_authentication/bundle_helper"
end

class WebauthnAuthenticationGenerator < ::Rails::Generators::Base
  include ActiveRecord::Generators::Migration
  include BundleHelper

  source_root File.expand_path("../templates", __FILE__)

  desc "Injects webauthn files to your application."

  class_option :api, type: :boolean,
    desc: "Generate API-only files, with no view templates"

  class_option :with_rails_authentication, type: :boolean,
    desc: "Run the Ruby on Rails authentication generator"

  def invoke_rails_authentication
    invoke "authentication" if options.with_rails_authentication?
  end

  def modify_sessions_controller
    gsub_file "app/controllers/sessions_controller.rb",
      /^  def create.*?^  end/m,
      <<~RUBY.strip_heredoc.indent(2)
        def create
          if user = User.authenticate_by(params.permit(:email_address, :password))
            if user.second_factor_enabled?
              session[:current_authentication] = { user_id: user.id }
              redirect_to new_second_factor_authentication_path
            else
              start_new_session_for user
              redirect_to after_authentication_url
            end
          else
            redirect_to new_session_path, alert: "Try another email address or password."
          end
        end
      RUBY
  end

  def inject_ensure_user_not_authenticated
    inject_into_file "app/controllers/concerns/authentication.rb",
      after: /def terminate_session.*?end\n/m do
        <<-RUBY.strip_heredoc.indent(4)

          def ensure_user_not_authenticated
            if Current.user
              redirect_to root_path
            end
          end
        RUBY
      end
  end

  def copy_controllers_and_concerns
    template "app/controllers/passkeys_controller.rb"
    template "app/controllers/webauthn_sessions_controller.rb"
    template "app/controllers/second_factor_authentication_controller.rb"
    template "app/controllers/second_factor_webauthn_credentials_controller.rb"
  end

  hook_for :template_engine do |template_engine|
    invoke template_engine unless options.api?
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

  def inject_js_packages
    if using_importmap?
      say %(Appending: pin "@github/webauthn-json/browser-ponyfill", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.browser-ponyfill.js")
      append_to_file "config/importmap.rb", %(pin "@github/webauthn-json/browser-ponyfill", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.browser-ponyfill.js"\n)
    elsif using_bun?
      say "Adding webauthn-json to your package manager"
      run "bun add @github/webauthn-json/browser-ponyfill"
    elsif has_package_json?
      say "Adding webauthn-json to your package manager"
      run "yarn add @github/webauthn-json/browser-ponyfill"
    else
      puts "You must either be running with node (package.json) or importmap-rails (config/importmap.rb) to use this gem."
    end
  end

  def inject_webauthn_dependency
    unless File.read(File.expand_path("Gemfile", destination_root)).include?('gem "webauthn"')
      bundle_command("add webauthn", {}, quiet: true)
    end
  end

  def copy_initializer_file
    template "config/initializers/webauthn.rb"
  end

  def inject_webauthn_content
    generate "migration", "AddWebauthnToUsers", "webauthn_id:string"
    inject_webauthn_content_to_user_model

    inject_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
      <<-RUBY.strip_heredoc.indent(2)
        resource :webauthn_session, only: [ :create, :destroy ] do
          post :get_options, on: :collection
        end

        resources :passkeys, only: [ :new, :create, :destroy ] do
          post :create_options, on: :collection
        end

        resources :second_factor_webauthn_credentials, only: [ :new, :create, :destroy ] do
          post :create_options, on: :collection
        end

        resource :second_factor_authentication, controller: "second_factor_authentication", only: [ :new, :create ] do
          post :get_options, on: :collection
        end
      RUBY
    end

    template "app/models/webauthn_credential.rb"
    generate "migration", "CreateWebauthnCredentials", "user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8} authentication_factor:integer{1}!"
  end

  hook_for :test_framework

  def final_message
    say ""
    say "Almost done! Now edit `config/initializers/webauthn.rb` and set the `allowed_origins` and `rp_name` for your app.", :yellow
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

  def inject_webauthn_content_to_user_model
    inject_into_file "app/models/user.rb", after: "normalizes :email_address, with: ->(e) { e.strip.downcase }\n"  do
      <<-RUBY.strip_heredoc.indent(2)

        has_many :webauthn_credentials, dependent: :destroy
        with_options class_name: "WebauthnCredential" do
          has_many :second_factor_webauthn_credentials, -> { second_factor }
          has_many :passkeys, -> { passkey }
        end

        after_initialize do
          self.webauthn_id ||= WebAuthn.generate_user_id
        end

        def second_factor_enabled?
          webauthn_credentials.any?
        end
      RUBY
    end
  end
end

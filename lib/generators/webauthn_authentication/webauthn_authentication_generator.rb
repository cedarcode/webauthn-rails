require "rails/generators/base"
require "rails/generators/active_record/migration"

class WebauthnAuthenticationGenerator < ::Rails::Generators::Base
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("../templates", __FILE__)

  desc "Injects webauthn files to your application."

  class_option :api, type: :boolean,
    desc: "Generate API-only files, with no view templates"

  invoke "authentication"

  def copy_controllers_and_concerns
    template "app/controllers/webauthn_credentials_controller.rb"
    template "app/controllers/registrations_controller.rb"
    template "app/controllers/sessions_controller.rb"
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

  def copy_initializer_file
    template "config/initializers/webauthn.rb"
  end

  def inject_session_and_current
    template "app/models/session.rb"
    template "app/models/current.rb"
    generate "migration", "CreateSessions", "user:references ip_address:string user_agent:string", "--force"
  end

  def inject_webauthn_content
    if File.exist?(File.join(destination_root, "app/models/user.rb"))
      inject_webauthn_content_to_user_model
      generate "migration", "AddWebauthnToUsers", "username:string:uniq webauthn_id:string"
    else
      template "app/models/user.rb"
      generate "migration", "CreateUsers", "username:string:uniq webauthn_id:string"
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
    generate "migration", "CreateWebauthnCredentials", "user:references! external_id:string:uniq public_key:string nickname:string sign_count:integer{8}"
  end

  hook_for :test_framework

  def final_message
    say ""
    say "Almost done! Now edit `config/initializers/webauthn.rb` and set the `allowed_origins` for your app.", :yellow
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
    inject_into_class "app/models/user.rb", "User" do
      <<-RUBY.strip_heredoc.indent(2)
        CREDENTIAL_MIN_AMOUNT = 1

        validates :username, presence: true, uniqueness: true

        has_many :webauthn_credentials, dependent: :destroy
        has_many :sessions, dependent: :destroy

        after_initialize do
          self.webauthn_id ||= WebAuthn.generate_user_id
        end

        def can_delete_credentials?
          webauthn_credentials.size > CREDENTIAL_MIN_AMOUNT
        end
      RUBY
    end
  end
end

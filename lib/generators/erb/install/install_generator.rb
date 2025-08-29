require "rails/generators/erb"

module Erb
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_files
        say "Add Webauthn views"
        template "app/views/webauthn_credentials/new.html.erb.tt"
        template "app/views/registrations/new.html.erb.tt"
        template "app/views/sessions/new.html.erb.tt"
      end
    end
  end
end

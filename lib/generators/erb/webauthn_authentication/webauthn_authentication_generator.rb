require "rails/generators/erb"

module Erb
  module Generators
    class WebauthnAuthenticationGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def create_files
        template "app/views/passkeys/new.html.erb.tt"
        template "app/views/second_factor_authentications/new.html.erb.tt"
        template "app/views/second_factor_webauthn_credentials/new.html.erb.tt"
      end

      def inject_into_rails_session_view
        append_to_file "app/views/sessions/new.html.erb" do
          <<-ERB.strip_heredoc
            <%= form_with(
              scope: :session,
              url: webauthn_session_path,
              method: :post,
              data: {
                controller: "webauthn-credentials",
                action: "webauthn-credentials#get:prevent",
                "webauthn-credentials-options-url-value": get_options_webauthn_session_path,
              }) do |f| %>
                <%= f.hidden_field :public_key_credential, data: { "webauthn-credentials-target": "credentialHiddenInput" } %>
                <%= f.submit "Sign In with Passkey"%>
            <% end %>
          ERB
        end
      end
    end
  end
end

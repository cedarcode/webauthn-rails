module Webauthn
  module Rails
    class ApplicationController < ::ApplicationController
      private

      def sign_in(user)
        session[:resource_id] = user.id
      end

      def sign_out
        session[:resource_id] = nil
      end

      def relying_party
        @relying_party ||=
          WebAuthn::RelyingParty.new(
            origin: Webauthn::Rails.webauthn_origin,
            name: "WebAuthn Rails Demo App"
          )
      end
    end
  end
end

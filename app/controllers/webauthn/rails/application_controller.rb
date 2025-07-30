module Webauthn
  module Rails
    class ApplicationController < ::ApplicationController
      private

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

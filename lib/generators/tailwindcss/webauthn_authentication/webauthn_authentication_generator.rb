require "generators/erb/webauthn_authentication/webauthn_authentication_generator"

module Tailwindcss
  module Generators
    class WebauthnAuthenticationGenerator < Erb::Generators::WebauthnAuthenticationGenerator
      hide!
      source_root File.expand_path("../templates", __FILE__)
    end
  end
end

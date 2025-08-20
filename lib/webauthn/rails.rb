require "webauthn/rails/version"
require "webauthn"

module Webauthn
  module Rails
    module Controllers
      autoload :Helpers, "webauthn/rails/controllers/helpers"
    end
  end
end

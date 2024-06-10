require "webauthn/rails/version"
require "webauthn/rails/engine"

module Webauthn
  module Rails

    module Controllers
      autoload :Helpers, 'webauthn/rails/controllers/helpers'
    end

    mattr_accessor :webauthn_origin

    mattr_accessor :resource_class
    @@resource_class = 'User'

    def self.resource_class
      @@resource_class.constantize
    end

    def self.resource_name
      @@resource_class.downcase
    end

    def self.configure
      yield self
    end

  end
end

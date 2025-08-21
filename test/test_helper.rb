$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "webauthn/rails"

require "minitest/autorun"
require "active_record/railtie"

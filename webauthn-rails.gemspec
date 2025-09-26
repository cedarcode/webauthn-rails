require_relative "lib/webauthn/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "webauthn-rails"
  spec.version     = Webauthn::Rails::VERSION
  spec.authors     = [ "Cedarcode" ]
  spec.email       = [ "webauthn@cedarcode.com" ]
  spec.homepage    = "https://github.com/cedarcode/webauthn-rails"
  spec.summary     = "Authentication for Rails using Passkeys"
  spec.description = "Provides a set of generators that will extend your Rails 8+ application's authentication
    to enable Passkey usage as first or second factor."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.require_paths = %w[lib]

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "railties", ">= 8"
end

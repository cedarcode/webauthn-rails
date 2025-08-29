require_relative "lib/webauthn/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "webauthn-rails"
  spec.version     = Webauthn::Rails::VERSION
  spec.authors     = [ "Santiago Rodriguez" ]
  spec.email       = [ "santiago.rodriguez@cedarcode.com" ]
  spec.homepage    = "https://github.com/cedarcode/webauthn-rails"
  spec.summary     = "Authentication for Rails using WebAuthn"
  spec.description = "Authentication for Rails using WebAuthn"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "railties", ">= 8"
  spec.add_dependency "webauthn", ">= 3"
end

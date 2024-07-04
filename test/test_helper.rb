# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# For generators
require "rails/generators/test_case"
require "generators/webauthn/rails/install_generator"

class ActiveSupport::TestCase
  def stub_create(fake_credential)
    # Encode binary fields to use in script
    encode(fake_credential, "rawId")
    encode(fake_credential["response"], "attestationObject")

    # Parse to avoid escaping already escaped characters
    fake_credential["response"]["clientDataJSON"] = JSON.parse(fake_credential["response"]["clientDataJSON"])

    page.execute_script(<<-SCRIPT)
      function encode(input) {
        return Uint8Array.from(input, c => c.charCodeAt(0));
      }

      let fakeCredential = JSON.parse('#{fake_credential.to_json}');

      fakeCredential.rawId = encode(atob(fakeCredential.rawId));
      fakeCredential.response.attestationObject = encode(atob(fakeCredential.response.attestationObject));
      fakeCredential.response.clientDataJSON = encode(JSON.stringify(fakeCredential.response.clientDataJSON));
      fakeCredential.getClientExtensionResults = function() { return {} };

      window.sinon.stub(navigator.credentials, 'create').resolves(fakeCredential);
    SCRIPT
  end

  def stub_get(fake_credential)
    # Encode binary fields to use in script
    encode(fake_credential, "rawId")
    encode(fake_credential["response"], "authenticatorData")
    encode(fake_credential["response"], "signature")

    # Parse to avoid escaping already escaped characters
    fake_credential["response"]["clientDataJSON"] = JSON.parse(fake_credential["response"]["clientDataJSON"])

    page.execute_script(<<-SCRIPT)
      function encode(input) {
        return Uint8Array.from(input, c => c.charCodeAt(0));
      }

      let fakeCredential = JSON.parse('#{fake_credential.to_json}');

      fakeCredential.rawId = encode(atob(fakeCredential.rawId));
      fakeCredential.response.authenticatorData = encode(atob(fakeCredential.response.authenticatorData));
      fakeCredential.response.clientDataJSON = encode(JSON.stringify(fakeCredential.response.clientDataJSON));
      fakeCredential.response.signature = encode(atob(fakeCredential.response.signature));
      fakeCredential.getClientExtensionResults = function() { return {} };

      window.sinon.stub(navigator.credentials, 'get').resolves(fakeCredential);
    SCRIPT
  end

  def encode(hash, key)
    hash[key] = Base64.strict_encode64(hash[key])
  end
end

module VirtualAuthenticatorTestHelper
  def add_virtual_authenticator
    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    options.user_verification = true
    options.user_verified = true
    options.resident_key = true
    page.driver.browser.add_virtual_authenticator(options)
  end

  def add_credential_to_authenticator(authenticator, user)
    raw_id = SecureRandom.random_bytes(16)
    credential_id = Base64.urlsafe_encode64(raw_id)
    key = OpenSSL::PKey.generate_key("ED25519")
    private_key = Base64.urlsafe_encode64(key.private_to_der)

    cose_public_key = COSE::Key::OKP.from_pkey(OpenSSL::PKey.read(key.public_to_der))
    cose_public_key.alg = -8
    public_key = Base64.urlsafe_encode64(cose_public_key.serialize)

    credential_json = {
      "credentialId" => credential_id,
      "isResidentCredential" => true,
      "rpId" => "localhost",
      "privateKey" => private_key,
      "signCount" => 0,
      "userHandle" => user.webauthn_id
    }

    authenticator.add_credential(credential_json)

    user.passkeys.create!(
      nickname: "My Security Key",
      external_id: Base64.urlsafe_encode64(raw_id, padding: false),
      public_key: public_key,
      sign_count: 0
    )
  end
end

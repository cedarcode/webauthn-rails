module VirtualAuthenticatorTestHelper
  def add_virtual_authenticator
    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    options.user_verification = true
    options.user_verified = true
    options.resident_key = true
    page.driver.browser.add_virtual_authenticator(options)
  end

  def add_passkey_to_authenticator(authenticator, user)
    add_credential_to_authenticator(authenticator, user, passkey: true)
  end

  def add_security_key_to_authenticator(authenticator, user)
    add_credential_to_authenticator(authenticator, user, passkey: false)
  end

  def add_credential_to_authenticator(authenticator, user, passkey:)
    credential_id = SecureRandom.random_bytes(16)
    encoded_credential_id = Base64.urlsafe_encode64(credential_id)
    key = OpenSSL::PKey.generate_key("ED25519")
    encoded_private_key = Base64.urlsafe_encode64(key.private_to_der)

    cose_public_key = COSE::Key::OKP.from_pkey(OpenSSL::PKey.read(key.public_to_der))
    cose_public_key.alg = -8
    encoded_cose_public_key = Base64.urlsafe_encode64(cose_public_key.serialize)

    credential_json = {
      "credentialId" => encoded_credential_id,
      "isResidentCredential" => passkey,
      "rpId" => "localhost",
      "privateKey" => encoded_private_key,
      "signCount" => 0
    }
    credential_json["userHandle"] = user.webauthn_id if passkey

    authenticator.add_credential(credential_json)

    user.webauthn_credentials.create!(
      nickname: "My Credential",
      external_id: Base64.urlsafe_encode64(credential_id, padding: false),
      public_key: encoded_cose_public_key,
      sign_count: 0,
      authentication_factor: passkey ? :first_factor : :second_factor
    )
  end
end

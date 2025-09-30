require "test_helper"
require "webauthn/fake_client"

class SecondFactorAuthenticationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)

    creation_options = WebAuthn::Credential.options_for_create(
      user: { id: @user.webauthn_id, name: @user.email_address },
      authenticator_selection: { resident_key: "discouraged", user_verification: "discouraged" }
    )
    create_options = @client.create(challenge: creation_options.challenge)
    credential = WebAuthn::Credential.from_create(create_options)

    WebauthnCredential.second_factor.create!(
      nickname: "My Security Key",
      user: @user,
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: 0
    )
  end

  test "get_options" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    post get_options_second_factor_authentication_url

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?
    assert body["userVerification"] == "discouraged"

    assert_equal session[:current_authentication][:challenge], body["challenge"]
  end

  test "create" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    post get_options_second_factor_authentication_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = @client.get(challenge: challenge, user_verified: false)

    post second_factor_authentication_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to root_path
    assert_nil session[:current_authentication]
  end

  test "create with a passkey" do
    client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)

    creation_options = WebAuthn::Credential.options_for_create(
      user: { id: @user.webauthn_id, name: @user.email_address },
      authenticator_selection: { resident_key: "discouraged", user_verification: "discouraged" }
    )
    create_options = client.create(challenge: creation_options.challenge)
    credential = WebAuthn::Credential.from_create(create_options)


    WebauthnCredential.passkey.create!(
      nickname: "My Security Key",
      user: @user,
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: 0
    )

    post session_path, params: { email_address: @user.email_address, password: "password" }

    post get_options_second_factor_authentication_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = client.get(challenge: challenge, user_verified: false)

    post second_factor_authentication_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to root_path
    assert_nil session[:current_authentication]
  end

  test "create with WebAuthn error" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    post get_options_second_factor_authentication_url

    public_key_credential = @client.get(
      user_verified: false
    )

    post second_factor_authentication_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to new_second_factor_authentication_path
    assert_match (/Verification failed/), flash[:alert]
    assert_nil session[:current_authentication]
  end

  test "create with unrecognized credential" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    post get_options_second_factor_authentication_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = @client.get(challenge: challenge, user_verified: false)
    public_key_credential["id"]= "invalid-id"

    post second_factor_authentication_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to new_second_factor_authentication_path
    assert_match (/Credential not recognized/), flash[:alert]
    assert_nil session[:current_authentication]
  end
end

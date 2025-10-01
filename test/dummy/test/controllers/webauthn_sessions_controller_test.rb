require "test_helper"
require "webauthn/fake_client"

class WebauthnSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)

    creation_options = WebAuthn::Credential.options_for_create(
      user: { id: @user.webauthn_id, name: @user.email_address }
    )
    create_options = @client.create(challenge: creation_options.challenge)
    credential = WebAuthn::Credential.from_create(create_options)

    WebauthnCredential.passkey.create!(
      nickname: "My Passkey",
      user: @user,
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: 0,
    )
  end

  test "get_options" do
    post get_options_webauthn_session_url

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?
    assert body["userVerification"] == "required"

    assert_equal session[:current_authentication][:challenge], body["challenge"]
  end

  test "create" do
    post get_options_webauthn_session_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = @client.get(challenge: challenge, user_verified: true)

    post webauthn_session_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to root_path
    assert_nil session[:current_authentication]
  end

  test "create with WebAuthn error" do
    post get_options_webauthn_session_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = @client.get(challenge: challenge, user_verified: false)

    post webauthn_session_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to new_session_path
    assert_match (/Verification failed/), flash[:alert]
    assert_nil session[:current_authentication]
  end

  test "create with unrecognized credential" do
    post get_options_webauthn_session_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = @client.get(challenge: challenge, user_verified: true)
    public_key_credential["id"] = "invalid-id"

    post webauthn_session_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to new_session_path
    assert_equal "Credential not recognized", flash[:alert]
    assert_nil session[:current_authentication]
  end

  test "create with a second factor credential" do
    client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)

    creation_options = WebAuthn::Credential.options_for_create(
      user: { id: @user.webauthn_id, name: @user.email_address }
    )
    create_options = client.create(challenge: creation_options.challenge)
    credential = WebAuthn::Credential.from_create(create_options)

    WebauthnCredential.second_factor.create!(
      nickname: "Second Factor Key",
      user: @user,
      external_id: credential.id,
      public_key: credential.public_key,
      sign_count: 0,
    )

    post get_options_webauthn_session_url
    challenge = session[:current_authentication][:challenge]

    public_key_credential = client.get(challenge: challenge, user_verified: true)

    post webauthn_session_url, params: {
      session: {
        public_key_credential: public_key_credential.to_json
      }
    }

    assert_redirected_to new_session_path
    assert_equal "Credential not recognized", flash[:alert]
    assert_nil session[:current_authentication]
  end

  test "destroy" do
    delete webauthn_session_url
    assert_redirected_to new_session_path
  end
end

require "test_helper"
require "webauthn/fake_client"

class PasskeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)
  end

  test "initiates Passkey creation when user is authenticated" do
    sign_in_as @user
    post create_options_passkeys_url

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?
    assert body["authenticatorSelection"]["residentKey"] == "required"
    assert body["authenticatorSelection"]["userVerification"] == "required"

    assert_equal session[:current_registration][:challenge], body["challenge"]
  end

  test "requires authentication to initiate Passkey creation" do
    post create_options_passkeys_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "creates passkey when user is authenticated" do
    sign_in_as @user

    post create_options_passkeys_url
    challenge = session[:current_registration][:challenge]

    public_key_credential = @client.create(
      challenge: challenge,
      user_verified: true,
    )

    assert_difference("WebauthnCredential.count", 1) do
      post passkeys_url, params: {
        credential: {
          nickname: "My Passkey",
          public_key_credential: public_key_credential.to_json
        }
      }
    end

    assert_redirected_to root_path
    assert_match (/Security Key registered successfully/), flash[:notice]
    assert_nil session[:current_registration]
  end

  test "does not create passkey when there is a Webauthn error" do
    sign_in_as @user

    post create_options_passkeys_url
    challenge = session[:current_registration][:challenge]

    public_key_credential = @client.create(
      challenge: challenge,
      user_verified: false,
    )

    assert_no_difference("WebauthnCredential.count") do
      post passkeys_url, params: {
        credential: {
          nickname: "My Passkey",
          public_key_credential: public_key_credential.to_json
        }
      }
    end

    assert_redirected_to new_passkey_path
    assert_match (/Verification failed/), flash[:alert]
    assert_nil session[:current_registration]
  end

  test "requires authentication to create passkey" do
    post passkeys_url, params: {
      credential: {
        nickname: "My Passkey",
        public_key_credential: "{}"
      }
    }

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "deletes passkey when user is authenticated" do
    credential = WebauthnCredential.create!(
      nickname: "My Passkey",
      user: @user,
      external_id: "external-id",
      public_key: "public-key",
      sign_count: 0,
      authentication_factor: 0
    )

    sign_in_as @user

    assert_difference("WebauthnCredential.count", -1) do
      delete passkey_url(credential)
    end
    assert_redirected_to root_path
  end
end

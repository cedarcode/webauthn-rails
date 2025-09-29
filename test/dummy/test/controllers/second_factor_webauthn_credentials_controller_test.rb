require "test_helper"
require "webauthn/fake_client"

class SecondFactorWebauthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first)
  end

  test "initiates second factor credential creation when user is authenticated" do
    sign_in_as @user
    post create_options_second_factor_webauthn_credentials_url

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?
    assert body["authenticatorSelection"]["residentKey"] == "discouraged"
    assert body["authenticatorSelection"]["userVerification"] == "discouraged"

    assert_equal session[:current_registration][:challenge], body["challenge"]
  end

  test "requires authentication to initiate second factor credential creation" do
    post create_options_second_factor_webauthn_credentials_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "creates second factor credential when user is authenticated" do
    sign_in_as @user

    post create_options_second_factor_webauthn_credentials_url
    challenge = session[:current_registration][:challenge]

    public_key_credential = @client.create(
      challenge: challenge,
      user_verified: false,
    )

    assert_difference("WebauthnCredential.second_factor.count", 1) do
      post second_factor_webauthn_credentials_url, params: {
        credential: {
          nickname: "My Security Key",
          public_key_credential: public_key_credential.to_json
        }
      }
    end

    assert_redirected_to root_path
    assert_match (/Security Key registered successfully/), flash[:notice]
    assert_nil session[:current_registration]
  end

  test "does not create second factor credential when there is a Webauthn error" do
    sign_in_as @user

    post create_options_second_factor_webauthn_credentials_url

    public_key_credential = @client.create(
      user_verified: false,
    )

    assert_no_difference("WebauthnCredential.count") do
      post second_factor_webauthn_credentials_url, params: {
        credential: {
          nickname: "My Security Key",
          public_key_credential: public_key_credential.to_json
        }
      }
    end

    assert_redirected_to new_second_factor_webauthn_credential_path
    assert_match (/Verification failed/), flash[:alert]
    assert_nil session[:current_registration]
  end

  test "requires authentication to create second factor credential" do
    post second_factor_webauthn_credentials_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "deletes second factor credential when user is authenticated" do
    credential = WebauthnCredential.second_factor.create!(
      user: @user,
      nickname: "My Security Key",
      external_id: "external_id",
      public_key: "public_key",
      sign_count: 0
    )

    sign_in_as @user

    assert_difference("WebauthnCredential.second_factor.count", -1) do
      delete second_factor_webauthn_credential_url(credential)
    end

    assert_redirected_to root_path
    assert_match (/Security Key deleted successfully/), flash[:notice]
  end
end

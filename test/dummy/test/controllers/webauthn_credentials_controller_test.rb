require "test_helper"

class WebauthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  test "initiates Passkey creation when user is authenticated" do
    user = User.create!(email_address: "alice@example.com", password: BCrypt::Password.create("S3cr3tP@ssw0rd!"))
    sign_in_as user
    post create_options_webauthn_credentials_url

    assert_response :success
  end

  test "requires authentication to initiate Passkey creation" do
    post create_options_webauthn_credentials_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end
end

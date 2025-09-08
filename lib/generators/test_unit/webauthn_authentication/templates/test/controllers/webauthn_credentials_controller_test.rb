require "test_helper"

class WebauthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  test "initiates Passkey creation when user is authenticated" do
    user = User.create!(email_address: "alice@example.com", password: "password")
    sign_in_as user
    post create_options_webauthn_credentials_url

    assert_response :success
  end

  test "requires authentication to initiate Passkey creation" do
    post create_options_webauthn_credentials_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  private

  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies[:session_id] = cookie_jar[:session_id]
    end
  end
end

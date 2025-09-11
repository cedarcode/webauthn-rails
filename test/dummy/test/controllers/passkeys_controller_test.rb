require "test_helper"

class PasskeysControllerTest < ActionDispatch::IntegrationTest
  test "initiates Passkey creation when user is authenticated" do
    user = users(:one)
    sign_in_as user
    post create_options_passkeys_url

    assert_response :success
  end

  test "requires authentication to initiate Passkey creation" do
    post create_options_passkeys_url

    assert_response :redirect
    assert_redirected_to new_session_url
  end
end

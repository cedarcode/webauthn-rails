require "test_helper"

class WebauthnSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should initiate sign_in using passkeys successfully" do
    post get_options_webauthn_session_url

    assert_response :success
  end
end

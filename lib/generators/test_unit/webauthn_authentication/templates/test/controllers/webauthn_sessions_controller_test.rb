require "test_helper"

class WebauthnSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should initiate registration successfully" do
    User.create!(username: "alice")

    post get_options_webauthn_session_url, params: { session: { username: "alice" } }

    assert_response :success
  end

  test "should return error if creating session with inexisting username" do
    post get_options_webauthn_session_url, params: { session: { username: "alice" } }

    assert_response :unprocessable_entity
    assert_equal [ "Username doesn't exist" ], JSON.parse(response.body)["errors"]
  end

  test "should return error if creating session with blank username" do
    post get_options_webauthn_session_url, params: { session: { username: "" } }

    assert_response :unprocessable_entity
    assert_equal [ "Username doesn't exist" ], JSON.parse(response.body)["errors"]
  end
end

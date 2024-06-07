require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should initiate registration successfully" do
    post webauthn_rails.registration_url, params: { registration: { username: "alice" }, format: :turbo_stream }

    assert_response :success
  end

  test "should return error if registrating taken username" do
    User.create!(username: "alice")

    post webauthn_rails.registration_url, params: { registration: { username: "alice" }, format: :turbo_stream }

    assert_response :unprocessable_entity
    assert_equal ["Username has already been taken"], JSON.parse(response.body)["errors"]
  end

  test "should return error if registrating blank username" do
    post webauthn_rails.registration_url, params: { registration: { username: "" }, format: :turbo_stream }

    assert_response :unprocessable_entity
    assert_equal ["Username can't be blank"], JSON.parse(response.body)["errors"]
  end
end

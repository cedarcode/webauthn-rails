require "application_system_test_case"
require "webauthn/fake_client"

class RegistrationTest < ApplicationSystemTestCase
  test "register user" do
    fake_origin = 'http://localhost:3030'
    fake_client = WebAuthn::FakeClient.new(fake_origin, encoding: false)
    fixed_challenge = SecureRandom.random_bytes(32)

    visit webauthn_rails.new_registration_path

    fake_credentials = fake_client.create(challenge: fixed_challenge, user_verified: true)
    stub_create(fake_credentials)

    fill_in "registration_username", with: "User1"
    fill_in "Security Key nickname", with: "USB key"

    WebAuthn::PublicKeyCredential::CreationOptions.stub_any_instance :raw_challenge, fixed_challenge do
      click_on "Sign up"
      # wait for async response
      assert_text "Your Security Keys"
    end

    assert_current_path "/"
    assert_text "USB key"
  end
end

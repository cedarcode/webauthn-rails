require "application_system_test_case"
require "webauthn/fake_client"

class SignInTest < ApplicationSystemTestCase
  test "register and then sign in" do
    fake_origin = 'http://localhost:3030'
    fake_client = WebAuthn::FakeClient.new(fake_origin, encoding: false)
    fixed_challenge = SecureRandom.random_bytes(32)

    visit webauthn_rails.new_registration_path
    assert_text "Sign in"

    fake_credentials = fake_client.create(challenge: fixed_challenge, user_verified: true)
    stub_create(fake_credentials)

    fill_in "Username", with: "User1"
    fill_in "Security Key nickname", with: "USB key"

    WebAuthn::PublicKeyCredential::CreationOptions.stub_any_instance :raw_challenge, fixed_challenge do
      click_on "Sign up"
      # wait for async response
      assert_text "Your Security Keys"
    end

    click_on "Sign out"
    assert_text "Sign in"

    fake_assertion = fake_client.get(challenge: fixed_challenge, user_verified: true)
    stub_get(fake_assertion)

    fill_in "Username", with: "User1"

    WebAuthn::PublicKeyCredential::RequestOptions.stub_any_instance :raw_challenge, fixed_challenge do
      click_button "Sign in"
      # wait for async response
      assert_text "Your Security Keys"
    end

    assert_current_path "/"
    assert_text "Your Security Keys"
  end
end

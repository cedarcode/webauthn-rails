require "test_helper"
require "webauthn/fake_client"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should initiate registration successfully" do
    post create_options_registration_url, params: { registration: { username: "alice" } }

    assert_response :success
  end

  test "should return error if registrating taken username" do
    User.create!(username: "alice")

    post create_options_registration_url, params: { registration: { username: "alice" } }

    assert_response :unprocessable_content
    assert_equal [ "Username has already been taken" ], JSON.parse(response.body)["errors"]
  end

  test "should return error if registrating blank username" do
    post create_options_registration_url params: { registration: { username: "" } }

    assert_response :unprocessable_content
    assert_equal [ "Username can't be blank" ], JSON.parse(response.body)["errors"]
  end

  test "should return error if registering existing credential" do
    raw_challenge = SecureRandom.random_bytes(32)
    challenge = WebAuthn.configuration.encoder.encode(raw_challenge)

    WebAuthn::PublicKeyCredential::CreationOptions.stub_any_instance(:raw_challenge, raw_challenge) do
      post create_options_registration_url, params: { registration: { username: "alice" } }

      assert_response :success
    end

    public_key_credential =
      WebAuthn::FakeClient
      .new("http://localhost:3030")
      .create(challenge:, user_verified: true)

    webauthn_credential = WebAuthn::Credential.from_create(public_key_credential)

    User.create!(
      username: "bob",
      webauthn_credentials: [
        WebauthnCredential.new(
          external_id: webauthn_credential.id,
          nickname: "Bob's USB Key",
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count
        )
      ]
    )

    assert_no_difference -> { User.count } do
      post(
        registration_url,
        params: { registration: { nickname: "USB Key", public_key_credential: public_key_credential.to_json } }
      )
    end

    assert_redirected_to new_registration_path
  end

  test "should register successfully" do
    raw_challenge = SecureRandom.random_bytes(32)
    challenge = WebAuthn.configuration.encoder.encode(raw_challenge)

    WebAuthn::PublicKeyCredential::CreationOptions.stub_any_instance(:raw_challenge, raw_challenge) do
      post create_options_registration_url, params: { registration: { username: "alice" } }

      assert_response :success
    end

    public_key_credential =
      WebAuthn::FakeClient
      .new("http://localhost:3030")
      .create(challenge:, user_verified: true)

    assert_difference "User.count", +1 do
      assert_difference "WebauthnCredential.count", +1 do
        post(
          registration_url,
          params: { registration: { nickname: "USB Key", public_key_credential: public_key_credential.to_json } },
        )
      end
    end

    assert_redirected_to "/"
  end
end

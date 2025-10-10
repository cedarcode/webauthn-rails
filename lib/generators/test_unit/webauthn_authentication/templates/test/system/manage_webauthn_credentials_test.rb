require "application_system_test_case"
require_relative "../test_helpers/virtual_authenticator_test_helper"

class ManageWebauthnCredentialsTest < ApplicationSystemTestCase
  include VirtualAuthenticatorTestHelper

  def setup
    @user = User.create!(email_address: "alice@example.com", password: "S3cr3tP@ssw0rd!")
    @authenticator = add_virtual_authenticator
  end

  def teardown
    @authenticator.remove!
  end

  test "adding a passkey" do
    sign_in_as(@user)

    visit new_passkey_path
    fill_in("Passkey nickname", with: "Touch ID")
    click_on "Add Passkey"

    assert_current_path root_path
    # Add custom assertions based on your application's behavior
    # assert_text "Passkey registered successfully"
  end

  test "signing in with existing passkey" do
    add_passkey_to_authenticator(@authenticator, @user)

    visit new_session_path
    click_on "Sign In with Passkey"

    assert_current_path root_path
    # Add custom assertions based on your application's behavior
  end

  test "adding a 2FA WebAuthn credential" do
    sign_in_as(@user)

    visit new_second_factor_webauthn_credential_path
    fill_in("Security Key nickname", with: "Touch ID")
    click_on "Add Security Key"

    assert_current_path root_path
    # Add custom assertions based on your application's behavior
    # assert_text "Security Key registered successfully"
  end

  test "sign in with existing 2FA WebAuthn credential" do
    add_security_key_to_authenticator(@authenticator, @user)

    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: @user.password
    click_on "Sign in"

    assert_current_path new_second_factor_authentication_path
    assert_selector "h3", text: "Two-factor authentication"
    click_on "Use Security Key"

    assert_current_path root_path
    # Add custom assertions based on your application's behavior
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password
    click_on "Sign in"

    assert_current_path root_path
  end
end

require "application_system_test_case"
require_relative "../test_helpers/virtual_authenticator_test_helper"

class ManageWebauthnCredentialsTest < ApplicationSystemTestCase
  include VirtualAuthenticatorTestHelper

  def setup
    user = User.create!(email_address: "alice@example.com", password: "S3cr3tP@ssw0rd!")
    sign_in_as(user)
    @authenticator = add_virtual_authenticator
  end

  def teardown
    @authenticator.remove!
  end

  test "adding a passkey and signing in" do
    visit new_passkey_path
    fill_in("Security Key nickname", with: "Touch ID")
    click_on "Add Security Key"

    assert_current_path root_path
    assert_no_selector "div", text: "Error registering credential"
    assert_no_selector "div", text: (/Verification failed:/)

    sign_out

    visit new_session_path
    click_on "Sign In with Passkey"

    assert_current_path root_path
    assert_no_selector "div", text: "Credential not recognized"
    assert_no_selector "div", text: (/Verification failed:/)
  end

  test "adding a 2FA WebAuthn credential and signing in" do
    visit new_second_factor_webauthn_credential_path
    fill_in("Security Key nickname", with: "Touch ID")
    click_on "Add Security Key"

    assert_current_path root_path
    assert_no_selector "div", text: "Error registering credential"
    assert_no_selector "div", text: (/Verification failed:/)

    sign_out

    visit new_session_path
    fill_in "email_address", with: "alice@example.com"
    fill_in "password", with: "S3cr3tP@ssw0rd!"
    click_on "Sign in"

    assert_selector "h3", text: "Two-factor authentication"
    click_on "Use Security Key"

    assert_current_path root_path
    assert_no_selector "div", text: "Credential not recognized"
    assert_no_selector "div", text: (/Verification failed:/)
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password
    click_on "Sign in"

    assert_current_path root_path
  end

  def sign_out
    Capybara.reset_sessions!
  end
end

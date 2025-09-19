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

  test "add credentials and sign in" do
    visit root_path

    click_on "Add credential"

    fill_in("Security Key nickname", with: "Touch ID")
    click_on "Add Security Key"

    assert_selector "div", text: "Security Key registered successfully"
    assert_selector "span", text: "Touch ID"
    assert_current_path "/"

    click_on "Sign out"
    assert_selector("input[type=submit][value='Sign in']")

    click_on "Sign In with Passkey"

    assert_selector "h3", text: "Your Security Keys"
    assert_current_path "/"
  end

  private

  def sign_in_as(user)
    visit new_session_path

    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password

    click_on "Sign in"

    assert_selector "h3", text: "Your Security Keys"
  end
end

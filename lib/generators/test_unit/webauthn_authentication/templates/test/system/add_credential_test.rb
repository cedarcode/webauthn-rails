require "application_system_test_case"
require_relative "../test_helpers/virtual_authenticator_test_helper"

class AddCredentialTest < ApplicationSystemTestCase
  include VirtualAuthenticatorTestHelper

  def setup
    sign_up(username: "User1")

    @authenticator = add_virtual_authenticator
  end

  def teardown
    @authenticator.remove!
  end

  test "add credentials" do
    visit root_path

    click_on "Add credential"

    fill_in("Security Key nickname", with: "Touch ID")

    click_on "Add Security Key"
    assert_selector "span", text: "Touch ID"

    assert_current_path "/"
    assert_selector "span", text: "USB key"
  end

  private

  def sign_up(username:, credential_nickname: "USB key")
    authenticator = add_virtual_authenticator

    visit new_registration_path

    fill_in "registration_username", with: username
    fill_in "Security Key nickname", with: credential_nickname

    click_on "Sign up"
    # wait for async response
    assert_selector "h3", text: "Your Security Keys"

    authenticator.remove!
  end
end

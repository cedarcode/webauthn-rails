require "application_system_test_case"

class SignInTest < ApplicationSystemTestCase
  def setup
    @authenticator = add_virtual_authenticator
  end

  def teardown
    @authenticator.remove!
  end

  test "register and then sign in" do
    visit webauthn_rails.new_registration_path

    fill_in "registration_username", with: "User1"
    fill_in "Security Key nickname", with: "USB key"

    click_on "Sign up"
    # wait for async response
    assert_selector "h3", text: "Your Security Keys"

    click_on "Sign out"
    assert_selector("input[type=submit][value='Sign in']")

    fill_in "Username", with: "User1"

    click_button "Sign in"
    assert_selector "h3", text: "Your Security Keys"
    assert_current_path "/"
  end
end

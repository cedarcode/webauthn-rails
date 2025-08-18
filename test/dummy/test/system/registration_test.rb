require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  def setup
    @authenticator = add_virtual_authenticator
  end

  def teardown
    @authenticator.remove!
  end

  test "register user" do
    visit new_registration_path

    fill_in "registration_username", with: "User1"
    fill_in "Security Key nickname", with: "USB key"

    click_on "Sign up"
    # wait for async response
    assert_selector "h3", text: "Your Security Keys"

    assert_current_path "/"
    assert_selector "span", text: "USB key"
  end
end

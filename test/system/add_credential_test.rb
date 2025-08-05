require "application_system_test_case"

class AddCredentialTest < ApplicationSystemTestCase
  def setup
    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    options.user_verification = true
    options.user_verified = true
    @authenticator = page.driver.browser.add_virtual_authenticator(options)
  end

  def teardown
    @authenticator.remove!
  end

  test "add credentials" do
    visit webauthn_rails.new_registration_path

    fill_in "registration_username", with: "User1"
    fill_in "Security Key nickname", with: "USB key"

    click_on "Sign up"
    # wait for async response
    assert_text "Your Security Keys"

    @authenticator.remove_all_credentials

    click_on "Add credential"

    fill_in("Security Key nickname", with: "Touch ID")

    click_on "Add Security Key"
    # wait for async response
    assert_text "Touch ID"

    assert_current_path "/"
    assert_text "USB key"
  end
end

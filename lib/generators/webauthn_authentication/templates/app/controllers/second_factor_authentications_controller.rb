class SecondFactorAuthenticationsController < ApplicationController
  allow_unauthenticated_access only: %i[new get_options create]
  before_action :require_no_authentication
  before_action :ensure_login_initiated

  def get_options
    get_options = WebAuthn::Credential.options_for_get(
      allow: user.webauthn_credentials.pluck(:external_id),
      user_verification: "discouraged"
    )
    session[:current_authentication][:challenge] = get_options.challenge

    render json: get_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_get(JSON.parse(session_params[:public_key_credential]))

    credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)
    unless credential
      redirect_to new_second_factor_authentication_path, alert: "Credential not recognized"
      return
    end

    begin
      webauthn_credential.verify(
        session[:current_authentication][:challenge] || session[:current_authentication]["challenge"],
        public_key: credential.public_key,
        sign_count: credential.sign_count
      )

      credential.update!(sign_count: webauthn_credential.sign_count)
      start_new_session_for user

      redirect_to after_authentication_url
    rescue WebAuthn::Error => e
      redirect_to new_second_factor_authentication_path, alert: "Verification failed: #{e.message}"
    end
  ensure
    session.delete(:current_authentication)
  end

  private

  def user
    @user ||= User.find_by(id: current_authentication_user_id)
  end

  def ensure_login_initiated
    if current_authentication_user_id.blank?
      redirect_to new_session_path
    end
  end

  def session_params
    params.expect(session: [ :public_key_credential ])
  end

  def current_authentication_user_id
    session.dig(:current_authentication, :user_id) || session.dig(:current_authentication, "user_id")
  end
end

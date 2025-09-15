class SecondFactorAuthenticationController < ApplicationController
  allow_unauthenticated_access only: %i[new get_options create]
  before_action :ensure_user_not_authenticated
  before_action :ensure_login_initiated

  def get_options
    get_options = WebAuthn::Credential.options_for_get(allow: user.second_factor_webauthn_credentials.pluck(:external_id))
    session[:current_authentication] = { challenge: get_options.challenge }

    render json: get_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_get(JSON.parse(session_params[:public_key_credential]))

    credential = user.second_factor_webauthn_credentials.find_by(external_id: webauthn_credential.id)

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
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:webauthn_user_id)
      session.delete(:current_authentication)
    end
  end

  private

  def user
    @user ||= User.find_by(id: session[:webauthn_user_id])
  end

  def ensure_login_initiated
    if session[:webauthn_user_id].blank?
      redirect_to new_session_path
    end
  end

  def ensure_user_not_authenticated
    if Current.user
      redirect_to root_path
    end
  end

  def session_params
    params.require(:session).permit(:public_key_credential)
  end
end

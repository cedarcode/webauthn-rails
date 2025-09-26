class WebauthnSessionsController < ApplicationController
  allow_unauthenticated_access only: %i[get_options create]

  def get_options
    get_options = WebAuthn::Credential.options_for_get(user_verification: "required")
    session[:current_authentication] = { challenge: get_options.challenge }

    render json: get_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_get(JSON.parse(session_params[:public_key_credential]))

    stored_credential = WebauthnCredential.passkey.find_by(external_id: webauthn_credential.id)
    unless stored_credential
      redirect_to new_session_path, alert: "Credential not recognized"
      return
    end

    begin
      webauthn_credential.verify(
        session[:current_authentication][:challenge] || session[:current_authentication]["challenge"],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count,
        user_verification: true,
      )

      stored_credential.update!(sign_count: webauthn_credential.sign_count)
      start_new_session_for stored_credential.user

      redirect_to after_authentication_url
    rescue WebAuthn::Error => e
      redirect_to new_session_path, alert: "Verification failed: #{e.message}"
    end
  ensure
    session.delete(:current_authentication)
  end

  def destroy
    terminate_session

    redirect_to new_session_path
  end

  private

  def session_params
    params.expect(session: [ :public_key_credential ])
  end
end

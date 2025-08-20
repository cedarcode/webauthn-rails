class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create_options create]

  def new
  end

  def create_options
    user = User.new(username: registration_params[:username])

    create_options = WebAuthn::Credential.options_for_create(
      user: {
        name: registration_params[:username],
        id: user.webauthn_id
      },
      authenticator_selection: { user_verification: "required" }
    )

    if user.valid?
      session[:current_registration] = { challenge: create_options.challenge, user_attributes: user.attributes }

      render json: create_options
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(JSON.parse(registration_params[:public_key_credential]))

    user = User.new(session[:current_registration][:user_attributes] || session[:current_registration]["user_attributes"])

    begin
      webauthn_credential.verify(
        session[:current_registration][:challenge] || session[:current_registration]["challenge"],
        user_verification: true,
      )

      user.webauthn_credentials.build(
        external_id: webauthn_credential.id,
        nickname: registration_params[:nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )

      if user.save
        start_new_session_for(user)

        redirect_to after_authentication_url, notice: "Security Key registered successfully"
      else
        redirect_to new_registration_path, alert: "Error registering credential"
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  private

  def registration_params
    params.require(:registration).permit(:username, :nickname, :public_key_credential)
  end
end

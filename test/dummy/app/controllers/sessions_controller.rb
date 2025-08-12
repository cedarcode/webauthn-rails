class SessionsController < ApplicationController
  include Authentication

  before_action :enforce_no_current_user, only: %i[new get_options create]

  def new
  end

  def get_options
    user = User.find_by(username: session_params[:username])

    if user
      get_options = WebAuthn::Credential.options_for_get(
        allow: user.webauthn_credentials.pluck(:external_id),
        user_verification: "required"
      )

      session[:current_authentication] = { challenge: get_options.challenge, username: session_params[:username] }

      render json: get_options
    else
      render json: { errors: [ "Username doesn't exist" ] }, status: :unprocessable_entity
    end
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_get(JSON.parse(session_params[:public_key_credential]))

    user = User.find_by(username: session[:current_authentication][:username] || session[:current_authentication]["username"])
    raise "user #{session[:current_authentication][:username]} never initiated sign up" unless user

    stored_credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)

    begin
      webauthn_credential.verify(
        session[:current_authentication][:challenge] || session[:current_authentication]["challenge"],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count,
        user_verification: true,
      )

      stored_credential.update!(sign_count: webauthn_credential.sign_count)
      sign_in(user)

      redirect_to root_path, notice: "Credential authenticated successfully"
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_authentication)
    end
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

  def session_params
    params.require(:session).permit(:username, :public_key_credential)
  end
end

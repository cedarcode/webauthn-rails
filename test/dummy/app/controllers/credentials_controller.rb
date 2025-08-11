class CredentialsController < ApplicationController
  before_action :enforce_current_user, only: %i[create_options create destroy]

  def create_options
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_id,
        name: current_user.username
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: { user_verification: "required" }
    )

    session[:current_registration] = { challenge: create_options.challenge }

    render json: create_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(JSON.parse(create_credential_params[:public_key_credential]))

    begin
      webauthn_credential.verify(
        session[:current_registration][:challenge] || session[:current_registration]["challenge"],
        user_verification: true,
      )

      credential = current_user.webauthn_credentials.find_or_initialize_by(
        external_id: webauthn_credential.id
      )

      if credential.update(
        nickname: create_credential_params[:nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )
        redirect_to main_app.root_path, notice: "Security Key registered successfully"
      else
        redirect_to main_app.new_credential_path, alert: "Error registering credential"
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  def destroy
    if current_user&.can_delete_credentials?
      current_user.webauthn_credentials.destroy(params[:id])
    end

    redirect_to main_app.root_path
  end

  private

  def create_credential_params
    params.require(:credential).permit(:nickname, :public_key_credential)
  end
end

class SecondFactorWebauthnCredentialsController < ApplicationController
  def create_options
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: Current.user.webauthn_id,
        name: Current.user.email_address
      },
      exclude: Current.user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: {
        resident_key: "discouraged",
        user_verification: "discouraged"
      }
    )

    session[:current_registration] = { challenge: create_options.challenge }

    render json: create_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(JSON.parse(create_credential_params[:public_key_credential]))

    begin
      webauthn_credential.verify(
        session[:current_registration][:challenge] || session[:current_registration]["challenge"]
      )

      credential = Current.user.second_factor_webauthn_credentials.find_or_initialize_by(
        external_id: webauthn_credential.id
      )

      if credential.update(
          nickname: create_credential_params[:nickname],
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count
      )
        redirect_to root_path, notice: "Security Key registered successfully"
      else
        redirect_to new_second_factor_webauthn_credential_path, alert: "Error registering credential"
      end
    rescue WebAuthn::Error => e
      redirect_to new_second_factor_webauthn_credential_path, alert: "Verification failed: #{e.message}"
    end
  ensure
    session.delete(:current_registration)
  end

  def destroy
    Current.user.second_factor_webauthn_credentials.destroy(params[:id])

    redirect_to root_path, notice: "Security Key deleted successfully"
  end

  private

  def create_credential_params
    params.expect(credential: [ :nickname, :public_key_credential ])
  end
end

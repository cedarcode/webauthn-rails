class PasskeysController < ApplicationController
  def create_options
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: Current.user.webauthn_id,
        name: Current.user.email_address
      },
      exclude: Current.user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: {
        resident_key: "required",
        user_verification: "required"
      }
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

      credential = Current.user.passkeys.find_or_initialize_by(
        external_id: webauthn_credential.id
      )

      if credential.update(
          nickname: create_credential_params[:nickname],
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count
      )
        redirect_to root_path, notice: "Passkey registered successfully"
      else
        flash[:alert] = "Error registering credential"
        render :new
      end
    rescue WebAuthn::Error => e
      redirect_to new_passkey_path, alert: "Verification failed: #{e.message}"
    end
  ensure
    session.delete(:current_registration)
  end

  def destroy
    Current.user.passkeys.destroy(params[:id])

    redirect_to root_path, notice: "Passkey deleted successfully"
  end

  private

  def create_credential_params
    params.expect(credential: [ :nickname, :public_key_credential ])
  end
end

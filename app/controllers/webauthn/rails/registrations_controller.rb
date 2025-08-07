module Webauthn
  module Rails
    class RegistrationsController < ApplicationController
      include Authentication

      before_action :enforce_no_current_user, only: %i[new create_options create]

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

          respond_to do |format|
            format.turbo_stream { render json: create_options }
          end
        else
          respond_to do |format|
            format.turbo_stream { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
          end
        end
      end

      def create
        webauthn_credential = WebAuthn::Credential.from_create(JSON.parse(registration_params[:credential]))

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
            sign_in(user)

            redirect_to main_app.root_path, notice: "Security Key registered successfully"
          else
            redirect_to webauthn_rails.new_registration_path, alert: "Error registering credential"
          end
        rescue WebAuthn::Error => e
          render json: "Verification failed: #{e.message}", status: :unprocessable_entity
        ensure
          session.delete(:current_registration)
        end
      end

      private

      def registration_params
        params.require(:registration).permit(:username, :nickname, :credential)
      end
    end
  end
end

module Webauthn
  module Rails
    class SessionsController < ApplicationController
      include Authentication

      before_action :enforce_no_current_user, only: %i[new create callback]

      def new
      end

      def create
        user = User.find_by(username: session_params[:username])

        if user
          get_options = WebAuthn::Credential.options_for_get(
            allow: user.credentials.pluck(:external_id),
            user_verification: "required"
          )

          session[:current_authentication] = { challenge: get_options.challenge, username: session_params[:username] }

          respond_to do |format|
            format.turbo_stream { render json: get_options }
          end
        else
          respond_to do |format|
            format.turbo_stream { render json: { errors: [ "Username doesn't exist" ] }, status: :unprocessable_entity }
          end
        end
      end

      def callback
        webauthn_credential = WebAuthn::Credential.from_get(params)

        user = User.find_by(username: session[:current_authentication][:username] || session[:current_authentication]["username"])
        raise "user #{session[:current_authentication][:username]} never initiated sign up" unless user

        stored_credential = user.credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

        begin
          webauthn_credential.verify(
            session[:current_authentication][:challenge] || session[:current_authentication]["challenge"],
            public_key: stored_credential.public_key,
            sign_count: stored_credential.sign_count,
            user_verification: true,
          )

          stored_credential.update!(sign_count: webauthn_credential.sign_count)
          sign_in(user)

          render json: { status: "ok" }, status: :ok
        rescue WebAuthn::Error => e
          render json: "Verification failed: #{e.message}", status: :unprocessable_entity
        ensure
          session.delete(:current_authentication)
        end
      end

      def destroy
        sign_out

        redirect_to main_app.root_path
      end

      private

      def session_params
        params.require(:session).permit(:username)
      end
    end
  end
end

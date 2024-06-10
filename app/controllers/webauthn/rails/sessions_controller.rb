module Webauthn
  module Rails
    class SessionsController < ApplicationController
      before_action :enforce_no_current_user, only: %i(new create callback)

      def new
      end

      def create
        resource = Webauthn::Rails.resource_class.find_by(username: session_params[:username])

        if resource
          get_options = relying_party.options_for_authentication(
            allow: resource.credentials.pluck(:external_id),
            user_verification: "required"
          )

          session[:current_authentication] = { challenge: get_options.challenge, username: session_params[:username] }

          respond_to do |format|
            format.turbo_stream { render json: get_options }
          end
        else
          respond_to do |format|
            format.turbo_stream { render json: { errors: ["Username doesn't exist"] }, status: :unprocessable_entity }
          end
        end
      end

      def callback
        resource = Webauthn::Rails.resource_class.find_by(username: session[:current_authentication][:username] || session[:current_authentication]['username'])
        raise "#{Webauthn::Rails.resource_class.to_s.downcase} #{session[:current_authentication][:username]} never initiated sign up" unless resource

        begin
          verified_webauthn_credential, stored_credential = relying_party.verify_authentication(
            params,
            session[:current_authentication][:challenge] || session[:current_authentication]['challenge'],
            user_verification: true,
          ) do |webauthn_credential|
            resource.credentials.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))
          end

          stored_credential.update!(sign_count: verified_webauthn_credential.sign_count)
          sign_in(resource)

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

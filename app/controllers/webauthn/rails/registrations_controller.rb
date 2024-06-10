module Webauthn
  module Rails
    class RegistrationsController < ApplicationController
      before_action :enforce_no_current_user, only: %i(new create callback)

      def new
      end

      def create
        resource = Webauthn::Rails.resource_class.new(username: params[:registration][:username])

        create_options = relying_party.options_for_registration(
          user: {
            name: params[:registration][:username],
            id: resource.webauthn_id
          },
          authenticator_selection: { user_verification: "required" }
        )

        if resource.valid?
          session[:current_registration] = { challenge: create_options.challenge, resource_attributes: resource.attributes }

          respond_to do |format|
            format.turbo_stream { render json: create_options }
          end
        else
          respond_to do |format|
            format.turbo_stream { render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity }
          end
        end
      end

      def callback
        resource = Webauthn::Rails.resource_class.create!(session[:current_registration][:resource_attributes] || session[:current_registration]['resource_attributes'])

        begin
          webauthn_credential = relying_party.verify_registration(
            params,
            session[:current_registration][:challenge] || session[:current_registration]['challenge'],
            user_verification: true,
          )

          credential = resource.credentials.build(
            external_id: Base64.strict_encode64(webauthn_credential.raw_id),
            nickname: params[:credential_nickname],
            public_key: webauthn_credential.public_key,
            sign_count: webauthn_credential.sign_count
          )

          if credential.save
            sign_in(resource)

            render json: { status: "ok" }, status: :ok
          else
            render json: "Couldn't register your Security Key", status: :unprocessable_entity
          end
        rescue WebAuthn::Error => e
          render json: "Verification failed: #{e.message}", status: :unprocessable_entity
        ensure
          session.delete(:current_registration)
        end
      end
    end
  end
end

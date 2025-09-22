class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :webauthn_credentials, dependent: :destroy
  with_options class_name: "WebauthnCredential" do
    has_many :second_factor_webauthn_credentials, -> { second_factor }
    has_many :passkeys, -> { passkey }
  end

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def second_factor_enabled?
    webauthn_credentials.any?
  end
end

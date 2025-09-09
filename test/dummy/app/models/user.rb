class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true

  CREDENTIAL_MIN_AMOUNT = 1

  has_many :webauthn_credentials, dependent: :destroy

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def can_delete_credentials?
    webauthn_credentials.size > CREDENTIAL_MIN_AMOUNT
  end
end

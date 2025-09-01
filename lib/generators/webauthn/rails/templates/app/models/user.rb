class User < ApplicationRecord
  CREDENTIAL_MIN_AMOUNT = 1

  validates :username, presence: true, uniqueness: true

  has_many :webauthn_credentials, dependent: :destroy
  has_many :sessions, dependent: :destroy

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def can_delete_credentials?
    webauthn_credentials.size > CREDENTIAL_MIN_AMOUNT
  end
end

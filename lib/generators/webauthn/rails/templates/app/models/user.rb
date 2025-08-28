class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true

  has_many :webauthn_credentials, dependent: :destroy

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end
end

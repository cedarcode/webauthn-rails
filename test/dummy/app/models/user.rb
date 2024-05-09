class User < ApplicationRecord
  has_many :credentials, dependent: :destroy, class_name: 'Webauthn::Rails::Credential'

  validates :username, presence: true, uniqueness: true

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end
end

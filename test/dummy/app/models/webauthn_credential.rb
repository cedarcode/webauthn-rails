class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, :public_key, :nickname, :sign_count, presence: true
  validates :external_id, uniqueness: true
  validates :sign_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**32 - 1 }

  enum :authentication_factor, { first_factor: 0, second_factor: 1 }

  scope :passkey, -> { first_factor }
end

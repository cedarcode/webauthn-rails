class AddAuthenticationFactorToWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :webauthn_credentials, :authentication_factor, :integer, default: 0, null: false, limit: 1
  end
end

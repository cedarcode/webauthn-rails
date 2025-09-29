class AddIsDiscoverableToWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :webauthn_credentials, :is_discoverable, :boolean
  end
end

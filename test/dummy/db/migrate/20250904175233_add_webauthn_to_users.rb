class AddWebauthnToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :webauthn_id, :string
  end
end

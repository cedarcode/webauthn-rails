class AddWebauthnToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
    add_column :users, :webauthn_id, :string
  end
end

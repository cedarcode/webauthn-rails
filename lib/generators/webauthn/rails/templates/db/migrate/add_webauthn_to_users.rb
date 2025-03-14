class AddWebauthnToUsers < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def up
    change_table :users do |t|
      t.string :username
      t.string :webauthn_id
    end

    add_index :users, :username, unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

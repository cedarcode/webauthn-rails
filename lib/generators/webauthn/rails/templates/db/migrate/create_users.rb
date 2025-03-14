class CreateUsers < ActiveRecord::Migration[<%= Rails.version.to_f %>]
  def change
    create_table :users do |t|
      t.string :username
      t.string :webauthn_id

      t.timestamps
    end
    add_index :users, :username, unique: true
  end
end

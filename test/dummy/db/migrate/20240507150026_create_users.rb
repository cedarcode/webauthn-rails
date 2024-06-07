class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :webauthn_id

      t.timestamps
    end
    add_index :users, :username, unique: true
  end
end

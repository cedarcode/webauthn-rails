class CreateWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id
      t.string :public_key
      t.string :nickname
      t.integer :sign_count, limit: 8
      t.integer :authentication_factor, limit: 1, null: false

      t.timestamps
    end
    add_index :webauthn_credentials, :external_id, unique: true
  end
end

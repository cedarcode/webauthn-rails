# This migration comes from webauthn_rails (originally 20240503193541)
class CreateWebauthnRailsCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :webauthn_rails_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id
      t.string :public_key
      t.string :nickname
      t.bigint :sign_count

      t.timestamps
    end
  end
end

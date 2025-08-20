class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :user_agent, null: false
      t.string :ip_address, null: false

      t.timestamps
    end
  end
end

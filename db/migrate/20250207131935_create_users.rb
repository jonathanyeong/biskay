class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :identifier, null: false
      t.string :app_password_digest, null: false

      t.timestamps
    end
    add_index :users, :identifier, unique: true
  end
end

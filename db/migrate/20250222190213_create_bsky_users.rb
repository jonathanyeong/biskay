class CreateBskyUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :bsky_users do |t|
      t.string :identifier
      t.string :app_password
      t.timestamps
    end
  end
end

class DropUsersTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :users
  end
end

class RemoveSkeetUserId < ActiveRecord::Migration[8.0]
  def change
    remove_column :skeets, :user_id
  end
end

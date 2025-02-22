class RemoveAppPasswordColumn < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :app_password
  end
end

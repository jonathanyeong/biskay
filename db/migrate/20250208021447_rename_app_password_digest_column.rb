class RenameAppPasswordDigestColumn < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :app_password_digest, :app_password
  end
end

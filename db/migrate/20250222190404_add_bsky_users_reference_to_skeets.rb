class AddBskyUsersReferenceToSkeets < ActiveRecord::Migration[8.0]
  def change
    change_table :skeets do |t|
      t.references :bsky_user
    end
  end
end

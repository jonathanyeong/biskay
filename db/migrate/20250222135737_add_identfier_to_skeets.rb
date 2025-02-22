class AddIdentfierToSkeets < ActiveRecord::Migration[8.0]
  def change
    change_table :skeets do |t|
      t.string :identifier
      t.index :identifier
    end
  end
end

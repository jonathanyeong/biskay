class CreateSkeets < ActiveRecord::Migration[8.0]
  def change
    create_table :skeets do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.string :status, default: "draft"
      t.datetime :scheduled_at
      t.datetime :posted_at

      t.timestamps
    end
  end
end

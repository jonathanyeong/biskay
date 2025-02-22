# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_22_190404) do
  create_table "bsky_users", force: :cascade do |t|
    t.string "identifier"
    t.string "app_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skeets", force: :cascade do |t|
    t.text "content"
    t.string "status", default: "draft"
    t.datetime "scheduled_at"
    t.datetime "posted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.integer "bsky_user_id"
    t.index ["bsky_user_id"], name: "index_skeets_on_bsky_user_id"
    t.index ["identifier"], name: "index_skeets_on_identifier"
  end
end

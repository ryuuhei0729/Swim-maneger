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

ActiveRecord::Schema[8.0].define(version: 2025_04_16_110910) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "best_time_tables", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "50m_fr", default: "-"
    t.string "50m_fr_note"
    t.string "100m_fr", default: "-"
    t.string "100m_fr_note"
    t.string "200m_fr", default: "-"
    t.string "200m_fr_note"
    t.string "400m_fr", default: "-"
    t.string "400m_fr_note"
    t.string "800m_fr", default: "-"
    t.string "800m_fr_note"
    t.string "50m_br", default: "-"
    t.string "50m_br_note"
    t.string "100m_br", default: "-"
    t.string "100m_br_note"
    t.string "200m_br", default: "-"
    t.string "200m_br_note"
    t.string "50m_ba", default: "-"
    t.string "50m_ba_note"
    t.string "100m_ba", default: "-"
    t.string "100m_ba_note"
    t.string "200m_ba", default: "-"
    t.string "200m_ba_note"
    t.string "50m_fly", default: "-"
    t.string "50m_fly_note"
    t.string "100m_fly", default: "-"
    t.string "100m_fly_note"
    t.string "200m_fly", default: "-"
    t.string "200m_fly_note"
    t.string "100m_im", default: "-"
    t.string "100m_im_note"
    t.string "200m_im", default: "-"
    t.string "200m_im_note"
    t.string "400m_im", default: "-"
    t.string "400m_im_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_best_time_tables_on_user_id"
  end

  create_table "user_auths", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email"], name: "index_user_auths_on_email", unique: true
    t.index ["reset_password_token"], name: "index_user_auths_on_reset_password_token", unique: true
    t.index ["user_id"], name: "index_user_auths_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "generation", null: false
    t.string "name", null: false
    t.string "gender", null: false
    t.date "birthday", null: false
    t.string "user_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_image_url", default: ""
    t.text "bio", default: ""
  end

  add_foreign_key "best_time_tables", "users"
  add_foreign_key "user_auths", "users"
end

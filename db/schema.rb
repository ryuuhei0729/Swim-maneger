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

ActiveRecord::Schema[8.0].define(version: 2025_04_19_051608) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "published_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_announcements_on_is_active"
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

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
    t.text "bio", default: ""
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "best_time_tables", "users"
  add_foreign_key "user_auths", "users"
end

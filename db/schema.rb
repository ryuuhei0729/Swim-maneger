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

ActiveRecord::Schema[8.0].define(version: 2025_05_02_063901) do
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
    t.text "content"
    t.boolean "is_active", default: true, null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_announcements_on_is_active"
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

  create_table "attendance", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "attendance_event_id", null: false
    t.string "status", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id"], name: "index_attendance_on_attendance_event_id"
    t.index ["user_id", "attendance_event_id"], name: "index_attendance_on_user_id_and_attendance_event_id", unique: true
    t.index ["user_id"], name: "index_attendance_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['present'::character varying, 'absent'::character varying, 'other'::character varying]::text[])", name: "check_status"
  end

  create_table "attendance_events", force: :cascade do |t|
    t.string "title", null: false
    t.date "date", null: false
    t.string "place"
    t.text "note"
    t.boolean "is_competition", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "milestone_reviews", force: :cascade do |t|
    t.bigint "milestone_id", null: false
    t.integer "achievement_rate", null: false
    t.text "negative_note", null: false
    t.text "positive_note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["milestone_id"], name: "index_milestone_reviews_on_milestone_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.bigint "objective_id", null: false
    t.string "milestone_type", null: false
    t.date "limit_date", null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["objective_id"], name: "index_milestones_on_objective_id"
    t.check_constraint "milestone_type::text = ANY (ARRAY['quality'::character varying, 'quantity'::character varying]::text[])", name: "check_milestone_type"
  end

  create_table "objectives", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "attendance_event_id", null: false
    t.bigint "style_id", null: false
    t.decimal "target_time", precision: 10, scale: 2, null: false
    t.text "quantity_note", null: false
    t.string "quality_title", null: false
    t.text "quality_note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id"], name: "index_objectives_on_attendance_event_id"
    t.index ["style_id"], name: "index_objectives_on_style_id"
    t.index ["user_id"], name: "index_objectives_on_user_id"
  end

  create_table "race_feedbacks", force: :cascade do |t|
    t.bigint "race_goal_id", null: false
    t.bigint "user_id", null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["race_goal_id"], name: "index_race_feedbacks_on_race_goal_id"
    t.index ["user_id"], name: "index_race_feedbacks_on_user_id"
  end

  create_table "race_goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "attendance_event_id", null: false
    t.bigint "style_id", null: false
    t.decimal "time", precision: 10, scale: 2, null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id"], name: "index_race_goals_on_attendance_event_id"
    t.index ["style_id"], name: "index_race_goals_on_style_id"
    t.index ["user_id"], name: "index_race_goals_on_user_id"
  end

  create_table "race_reviews", force: :cascade do |t|
    t.bigint "race_goal_id", null: false
    t.bigint "style_id", null: false
    t.decimal "time", precision: 10, scale: 2, null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["race_goal_id"], name: "index_race_reviews_on_race_goal_id"
    t.index ["style_id"], name: "index_race_reviews_on_style_id"
  end

  create_table "records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "style_id", null: false
    t.decimal "time", precision: 10, scale: 2, null: false
    t.text "note"
    t.string "video_url"
    t.bigint "attendance_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id"], name: "index_records_on_attendance_event_id"
    t.index ["style_id"], name: "index_records_on_style_id"
    t.index ["user_id"], name: "index_records_on_user_id"
  end

  create_table "styles", force: :cascade do |t|
    t.string "name_jp", null: false
    t.string "name", null: false
    t.string "style", null: false
    t.integer "distance", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["style", "distance"], name: "index_styles_on_style_and_distance", unique: true
  end

  create_table "user_auths", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type"], name: "index_users_on_user_type"
    t.check_constraint "gender::text = ANY (ARRAY['male'::character varying, 'female'::character varying]::text[])", name: "check_gender"
    t.check_constraint "user_type::text = ANY (ARRAY['director'::character varying, 'coach'::character varying, 'player'::character varying, 'manager'::character varying]::text[])", name: "check_user_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendance", "attendance_events"
  add_foreign_key "attendance", "users"
  add_foreign_key "milestone_reviews", "milestones"
  add_foreign_key "milestones", "objectives"
  add_foreign_key "objectives", "attendance_events"
  add_foreign_key "objectives", "styles"
  add_foreign_key "objectives", "users"
  add_foreign_key "race_feedbacks", "race_goals"
  add_foreign_key "race_feedbacks", "users"
  add_foreign_key "race_goals", "attendance_events"
  add_foreign_key "race_goals", "styles"
  add_foreign_key "race_goals", "users"
  add_foreign_key "race_reviews", "race_goals"
  add_foreign_key "race_reviews", "styles"
  add_foreign_key "records", "attendance_events"
  add_foreign_key "records", "styles"
  add_foreign_key "records", "users"
  add_foreign_key "user_auths", "users"
end

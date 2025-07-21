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

ActiveRecord::Schema[8.0].define(version: 2025_07_21_135229) do
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
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.index ["attendance_event_id"], name: "index_attendance_on_attendance_event_id"
    t.index ["user_id", "attendance_event_id"], name: "index_attendance_on_user_id_and_attendance_event_id", unique: true
    t.index ["user_id"], name: "index_attendance_on_user_id"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2])", name: "check_status"
  end

  create_table "entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "attendance_event_id", null: false
    t.integer "style_id", null: false
    t.decimal "entry_time", precision: 10, scale: 2, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id", "user_id", "style_id"], name: "index_entries_unique_combination", unique: true
    t.index ["attendance_event_id"], name: "index_entries_on_attendance_event_id"
    t.index ["style_id"], name: "index_entries_on_style_id"
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.date "date", null: false
    t.string "place"
    t.text "note"
    t.string "type", default: "Event", null: false
    t.boolean "is_attendance", default: false, null: false
    t.integer "attendance_status", default: 0
    t.boolean "is_competition", default: false
    t.integer "entry_status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_events_on_date"
    t.index ["is_attendance"], name: "index_events_on_is_attendance"
    t.index ["is_competition"], name: "index_events_on_is_competition"
    t.index ["type", "date"], name: "index_events_on_type_and_date"
    t.index ["type"], name: "index_events_on_type"
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
    t.check_constraint "milestone_type::text = ANY (ARRAY['quality'::character varying::text, 'quantity'::character varying::text])", name: "check_milestone_type"
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

  create_table "practice_logs", force: :cascade do |t|
    t.bigint "attendance_event_id", null: false
    t.json "tags"
    t.string "style"
    t.integer "rep_count", null: false
    t.integer "set_count", null: false
    t.integer "distance", null: false
    t.decimal "circle", precision: 10, scale: 2, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_event_id"], name: "index_practice_logs_on_attendance_event_id"
    t.index ["style"], name: "index_practice_logs_on_style"
  end

  create_table "practice_times", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "practice_log_id", null: false
    t.integer "rep_number", null: false
    t.integer "set_number", null: false
    t.decimal "time", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_log_id", "user_id", "rep_number", "set_number"], name: "index_practice_times_on_unique_combination", unique: true
    t.index ["practice_log_id"], name: "index_practice_times_on_practice_log_id"
    t.index ["user_id"], name: "index_practice_times_on_user_id"
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

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "split_times", force: :cascade do |t|
    t.bigint "record_id", null: false
    t.bigint "race_goal_id", null: false
    t.integer "distance", null: false
    t.decimal "split_time", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["race_goal_id"], name: "index_split_times_on_race_goal_id"
    t.index ["record_id"], name: "index_split_times_on_record_id"
  end

  create_table "styles", force: :cascade do |t|
    t.string "name_jp", null: false
    t.string "name", null: false
    t.integer "distance", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "style"
    t.check_constraint "style = ANY (ARRAY[0, 1, 2, 3, 4])", name: "check_style"
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
    t.string "authentication_token"
    t.index ["authentication_token"], name: "index_user_auths_on_authentication_token", unique: true
    t.index ["email"], name: "index_user_auths_on_email", unique: true
    t.index ["reset_password_token"], name: "index_user_auths_on_reset_password_token", unique: true
    t.index ["user_id"], name: "index_user_auths_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "generation", null: false
    t.string "name", null: false
    t.date "birthday"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "gender"
    t.integer "user_type"
    t.check_constraint "gender = ANY (ARRAY[0, 1, 2])", name: "check_gender"
    t.check_constraint "user_type = ANY (ARRAY[0, 1, 2, 3])", name: "check_user_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendance", "events", column: "attendance_event_id"
  add_foreign_key "attendance", "users"
  add_foreign_key "entries", "events", column: "attendance_event_id"
  add_foreign_key "entries", "styles"
  add_foreign_key "entries", "users"
  add_foreign_key "milestone_reviews", "milestones"
  add_foreign_key "milestones", "objectives"
  add_foreign_key "objectives", "events", column: "attendance_event_id"
  add_foreign_key "objectives", "styles"
  add_foreign_key "objectives", "users"
  add_foreign_key "practice_logs", "events", column: "attendance_event_id"
  add_foreign_key "practice_times", "practice_logs"
  add_foreign_key "practice_times", "users"
  add_foreign_key "race_feedbacks", "race_goals"
  add_foreign_key "race_feedbacks", "users"
  add_foreign_key "race_goals", "events", column: "attendance_event_id"
  add_foreign_key "race_goals", "styles"
  add_foreign_key "race_goals", "users"
  add_foreign_key "race_reviews", "race_goals"
  add_foreign_key "race_reviews", "styles"
  add_foreign_key "records", "events", column: "attendance_event_id"
  add_foreign_key "records", "styles"
  add_foreign_key "records", "users"
  add_foreign_key "split_times", "race_goals"
  add_foreign_key "split_times", "records"
  add_foreign_key "user_auths", "users"
end

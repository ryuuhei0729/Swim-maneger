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

ActiveRecord::Schema[8.0].define(version: 2025_08_28_063023) do
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
    t.index ["is_active", "published_at"], name: "index_announcements_on_active_and_published"
    t.index ["is_active"], name: "index_announcements_on_is_active"
    t.index ["published_at", "is_active"], name: "index_announcements_on_published_at_and_is_active"
    t.index ["published_at"], name: "index_announcements_on_published_at"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "attendance_event_id", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.index ["attendance_event_id", "status"], name: "index_attendances_on_event_and_status"
    t.index ["attendance_event_id"], name: "index_attendances_on_attendance_event_id"
    t.index ["status", "created_at"], name: "index_attendances_on_status_and_created_at"
    t.index ["user_id", "attendance_event_id"], name: "index_attendances_on_user_id_and_attendance_event_id", unique: true
    t.index ["user_id", "status"], name: "index_attendances_on_user_id_and_status"
    t.index ["user_id"], name: "index_attendances_on_user_id"
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
    t.index ["attendance_event_id", "entry_time"], name: "index_entries_on_event_and_time"
    t.index ["attendance_event_id", "user_id", "style_id"], name: "index_entries_unique_combination", unique: true
    t.index ["attendance_event_id"], name: "index_entries_on_attendance_event_id"
    t.index ["style_id"], name: "index_entries_on_style_id"
    t.index ["user_id", "attendance_event_id", "style_id"], name: "index_entries_on_user_event_style"
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
    t.index ["date", "type"], name: "index_events_on_date_and_type"
    t.index ["date"], name: "index_events_date_attendance_only", where: "(is_attendance = true)"
    t.index ["date"], name: "index_events_on_date"
    t.index ["is_attendance"], name: "index_events_on_is_attendance"
    t.index ["is_competition", "entry_status"], name: "index_events_on_competition_entry_status"
    t.index ["is_competition"], name: "index_events_on_is_competition"
    t.index ["type", "date", "is_attendance"], name: "index_events_on_type_date_attendance"
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
    t.index ["objective_id", "limit_date"], name: "index_milestones_on_objective_and_limit_date"
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
    t.index ["user_id", "attendance_event_id"], name: "index_objectives_on_user_and_event"
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
    t.index ["style", "created_at"], name: "index_practice_logs_on_style_and_created_at"
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
    t.index ["practice_log_id", "rep_number", "set_number"], name: "index_practice_times_on_log_rep_set"
    t.index ["practice_log_id", "user_id", "rep_number", "set_number"], name: "index_practice_times_on_unique_combination", unique: true
    t.index ["practice_log_id", "user_id"], name: "index_practice_times_on_practice_log_and_user"
    t.index ["practice_log_id"], name: "index_practice_times_on_practice_log_id"
    t.index ["user_id", "created_at"], name: "index_practice_times_on_user_and_created_at"
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
    t.index ["user_id", "attendance_event_id"], name: "index_race_goals_on_user_and_event"
    t.index ["user_id"], name: "index_race_goals_on_user_id"
  end

  create_table "race_reviews", force: :cascade do |t|
    t.bigint "race_goal_id", null: false
    t.bigint "style_id", null: false
    t.decimal "time", precision: 10, scale: 2, null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["race_goal_id", "created_at"], name: "index_race_reviews_on_goal_and_created"
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
    t.index ["attendance_event_id", "created_at"], name: "index_records_on_event_created"
    t.index ["attendance_event_id"], name: "index_records_on_attendance_event_id"
    t.index ["style_id", "time"], name: "index_records_on_style_id_and_time"
    t.index ["style_id"], name: "index_records_on_style_id"
    t.index ["time"], name: "index_records_time_competition_only", where: "(attendance_event_id IS NOT NULL)"
    t.index ["user_id", "style_id", "created_at"], name: "index_records_on_user_style_created"
    t.index ["user_id", "style_id", "time"], name: "index_records_on_user_style_time"
    t.index ["user_id", "style_id"], name: "index_records_on_user_id_and_style_id"
    t.index ["user_id", "time"], name: "index_records_on_user_id_and_time"
    t.index ["user_id"], name: "index_records_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id", "updated_at"], name: "index_sessions_on_id_and_updated"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "split_times", force: :cascade do |t|
    t.bigint "record_id", null: false
    t.bigint "race_goal_id"
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
    t.index "EXTRACT(month FROM birthday), EXTRACT(day FROM birthday)", name: "index_users_on_birthday_month_day"
    t.index ["generation", "user_type"], name: "index_users_on_generation_and_user_type"
    t.index ["name", "generation"], name: "index_users_on_name_and_generation"
    t.index ["name"], name: "index_users_name_players_only", where: "(user_type = 0)"
    t.index ["user_type", "generation"], name: "index_users_on_user_type_and_generation"
    t.check_constraint "gender = ANY (ARRAY[0, 1, 2])", name: "check_gender"
    t.check_constraint "user_type = ANY (ARRAY[0, 1, 2, 3])", name: "check_user_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "events", column: "attendance_event_id"
  add_foreign_key "attendances", "users"
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

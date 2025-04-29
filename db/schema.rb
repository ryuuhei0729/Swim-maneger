# このファイルは、データベースの現在の状態から自動生成されています。
# このファイルを直接編集する代わりに、Active Recordのマイグレーション機能を使用して
# データベースを段階的に変更し、その後このスキーマ定義を再生成してください。
# このファイルは、`bin/rails db:schema:load`を実行する際にRailsがスキーマを定義するために使用されます。
# 新しいデータベースを作成する際、`bin/rails db:schema:load`を実行する方が、
# すべてのマイグレーションを最初から実行するよりも高速で、エラーが発生しにくい傾向があります。
# 古いマイグレーションは、外部依存関係やアプリケーションコードを使用している場合、
# 正しく適用されない可能性があります。
# このファイルをバージョン管理システムにチェックインすることを強く推奨します。

ActiveRecord::Schema[8.0].define(version: 2025_04_28_162535) do
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

  create_table "attendance_events", force: :cascade do |t|
    t.string "title"
    t.date "date"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "place"
  end

  create_table "attendance", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "attendance_event_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.index ["attendance_event_id"], name: "index_attendance_on_attendance_event_id"
    t.index ["user_id"], name: "index_attendance_on_user_id"
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
  add_foreign_key "attendance", "attendance_events"
  add_foreign_key "attendance", "users"
  add_foreign_key "best_time_tables", "users"
  add_foreign_key "user_auths", "users"
end

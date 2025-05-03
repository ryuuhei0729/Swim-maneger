class CreateAllTables < ActiveRecord::Migration[8.0]
  def change
    # テーブルが存在しない場合のみ作成
    unless table_exists?(:users)
      # User
      create_table :users do |t|
        t.integer :generation, null: false
        t.string :name, null: false
        t.string :gender, null: false
        t.date :birthday, null: false
        t.string :user_type, null: false
        t.string :profile_image_url
        t.text :bio, default: ""

        t.timestamps
      end
    end

    unless table_exists?(:user_auths)
      # UserAuth (Devise)
      create_table :user_auths do |t|
        t.string :email, null: false, default: ""
        t.string :encrypted_password, null: false, default: ""
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.datetime :remember_created_at
        t.integer :sign_in_count, default: 0, null: false
        t.datetime :current_sign_in_at
        t.datetime :last_sign_in_at
        t.string :current_sign_in_ip
        t.string :last_sign_in_ip
        t.references :user, foreign_key: true

        t.timestamps null: false
      end

      add_index :user_auths, :email, unique: true
      add_index :user_auths, :reset_password_token, unique: true
    end

    unless table_exists?(:best_time_tables)
      # BestTimeTable
      create_table :best_time_tables do |t|
        t.references :user, null: false, foreign_key: true
        t.decimal :"50m_fr", precision: 5, scale: 2, default: 0
        t.text :"50m_fr_note"
        t.decimal :"100m_fr", precision: 5, scale: 2, default: 0
        t.text :"100m_fr_note"
        t.decimal :"200m_fr", precision: 5, scale: 2, default: 0
        t.text :"200m_fr_note"
        t.decimal :"400m_fr", precision: 5, scale: 2, default: 0
        t.text :"400m_fr_note"
        t.decimal :"800m_fr", precision: 5, scale: 2, default: 0
        t.text :"800m_fr_note"
        t.decimal :"50m_fly", precision: 5, scale: 2, default: 0
        t.text :"50m_fly_note"
        t.decimal :"100m_fly", precision: 5, scale: 2, default: 0
        t.text :"100m_fly_note"
        t.decimal :"200m_fly", precision: 5, scale: 2, default: 0
        t.text :"200m_fly_note"
        t.decimal :"50m_ba", precision: 5, scale: 2, default: 0
        t.text :"50m_ba_note"
        t.decimal :"100m_ba", precision: 5, scale: 2, default: 0
        t.text :"100m_ba_note"
        t.decimal :"200m_ba", precision: 5, scale: 2, default: 0
        t.text :"200m_ba_note"
        t.decimal :"50m_br", precision: 5, scale: 2, default: 0
        t.text :"50m_br_note"
        t.decimal :"100m_br", precision: 5, scale: 2, default: 0
        t.text :"100m_br_note"
        t.decimal :"200m_br", precision: 5, scale: 2, default: 0
        t.text :"200m_br_note"
        t.decimal :"100m_im", precision: 5, scale: 2, default: 0
        t.text :"100m_im_note"
        t.decimal :"200m_im", precision: 5, scale: 2, default: 0
        t.text :"200m_im_note"
        t.decimal :"400m_im", precision: 5, scale: 2, default: 0
        t.text :"400m_im_note"
        t.timestamps
      end

      add_index :best_time_tables, :user_id
    end

    unless table_exists?(:announcements)
      # Announcement
      create_table :announcements do |t|
        t.string :title, null: false
        t.text :content, null: false
        t.boolean :is_active, default: true, null: false
        t.datetime :published_at, default: -> { "CURRENT_TIMESTAMP" }, null: false

        t.timestamps
      end

      add_index :announcements, :is_active
      add_index :announcements, :published_at
    end

    unless table_exists?(:attendance_events)
      # AttendanceEvent
      create_table :attendance_events do |t|
        t.string :title
        t.date :date
        t.string :place
        t.text :note
        t.boolean :competition, default: false, null: false
        t.timestamps
      end
    end

    unless table_exists?(:attendance)
      # Attendance
      create_table :attendance do |t|
        t.references :user, null: false, foreign_key: true
        t.references :attendance_event, null: false, foreign_key: true
        t.string :status
        t.text :note

        t.timestamps
      end

      add_index :attendance, [:user_id, :attendance_event_id], unique: true
    end
  end
end

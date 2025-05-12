class CreateAllTablesV2 < ActiveRecord::Migration[7.0]
  def up
    # ユーザー関連のテーブル
    create_table :users do |t|
      t.integer :generation, null: false
      t.string :name, null: false
      t.string :gender, null: false
      t.date :birthday, null: false
      t.string :user_type, null: false
      t.text :bio
      t.timestamps
    end

    # お知らせテーブル
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :content
      t.boolean :is_active, null: false, default: true
      t.datetime :published_at, null: false
      t.timestamps
    end

    create_table :user_auths do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
    end

    # 種目テーブル
    create_table :styles do |t|
      t.string :name_jp, null: false
      t.string :name, null: false
      t.string :style, null: false
      t.integer :distance, null: false
      t.timestamps
    end

    # 出席イベントテーブル
    create_table :attendance_events do |t|
      t.string :title, null: false
      t.date :date, null: false
      t.string :place
      t.text :note
      t.boolean :is_competition, default: false, null: false
      t.timestamps
    end

    # 出席テーブル
    create_table :attendance do |t|
      t.references :user, null: false, foreign_key: true
      t.references :attendance_event, null: false, foreign_key: true
      t.string :status, null: false
      t.text :note
      t.timestamps
    end

    # 記録テーブル
    create_table :records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :style, null: false, foreign_key: true
      t.decimal :time, precision: 10, scale: 2, null: false
      t.text :note
      t.string :video_url
      t.references :attendance_event, null: true, foreign_key: true
      t.timestamps
    end

    # 目標テーブル
    create_table :objectives do |t|
      t.references :user, null: false, foreign_key: true
      t.references :attendance_event, null: false, foreign_key: true
      t.references :style, null: false, foreign_key: true
      t.decimal :target_time, precision: 10, scale: 2, null: false
      t.text :quantity_note, null: false
      t.string :quality_title, null: false
      t.text :quality_note, null: false
      t.timestamps
    end

    # マイルストーンテーブル
    create_table :milestones do |t|
      t.references :objective, null: false, foreign_key: true
      t.string :milestone_type, null: false
      t.date :limit_date, null: false
      t.text :note, null: false
      t.timestamps
    end

    # マイルストーンレビューテーブル
    create_table :milestone_reviews do |t|
      t.references :milestone, null: false, foreign_key: true
      t.integer :achievement_rate, null: false
      t.text :negative_note, null: false
      t.text :positive_note, null: false
      t.timestamps
    end

    # レース目標テーブル
    create_table :race_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :attendance_event, null: false, foreign_key: true
      t.references :style, null: false, foreign_key: true
      t.decimal :time, precision: 10, scale: 2, null: false
      t.text :note, null: false
      t.timestamps
    end

    # レースレビューテーブル
    create_table :race_reviews do |t|
      t.references :race_goal, null: false, foreign_key: true
      t.references :style, null: false, foreign_key: true
      t.decimal :time, precision: 10, scale: 2, null: false
      t.text :note, null: false
      t.timestamps
    end

    # レースフィードバックテーブル
    create_table :race_feedbacks do |t|
      t.references :race_goal, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :note, null: false
      t.timestamps
    end

    # インデックス
    add_index :user_auths, :email, unique: true
    add_index :user_auths, :reset_password_token, unique: true
    add_index :users, :user_type
    add_index :styles, [:style, :distance], unique: true
    add_index :attendance, [:user_id, :attendance_event_id], unique: true
    add_index :announcements, :published_at
    add_index :announcements, :is_active

    # 制約
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT check_gender
      CHECK (gender IN ('male', 'female'));

      ALTER TABLE users
      ADD CONSTRAINT check_user_type
      CHECK (user_type IN ('director', 'coach', 'player', 'manager'));

      ALTER TABLE attendance
      ADD CONSTRAINT check_status
      CHECK (status IN ('present', 'absent', 'other'));

      ALTER TABLE milestones
      ADD CONSTRAINT check_milestone_type
      CHECK (milestone_type IN ('quality', 'quantity'));
    SQL

    # 種目の初期データ
    styles = [
      { name_jp: "50m自由形", name: "50Fr", style: "fr", distance: 50 },
      { name_jp: "100m自由形", name: "100Fr", style: "fr", distance: 100 },
      { name_jp: "200m自由形", name: "200Fr", style: "fr", distance: 200 },
      { name_jp: "400m自由形", name: "400Fr", style: "fr", distance: 400 },
      { name_jp: "800m自由形", name: "800Fr", style: "fr", distance: 800 },
      { name_jp: "50m平泳ぎ", name: "50Br", style: "br", distance: 50 },
      { name_jp: "100m平泳ぎ", name: "100Br", style: "br", distance: 100 },
      { name_jp: "200m平泳ぎ", name: "200Br", style: "br", distance: 200 },
      { name_jp: "50m背泳ぎ", name: "50Ba", style: "ba", distance: 50 },
      { name_jp: "100m背泳ぎ", name: "100Ba", style: "ba", distance: 100 },
      { name_jp: "200m背泳ぎ", name: "200Ba", style: "ba", distance: 200 },
      { name_jp: "50mバタフライ", name: "50Fly", style: "fly", distance: 50 },
      { name_jp: "100mバタフライ", name: "100Fly", style: "fly", distance: 100 },
      { name_jp: "200mバタフライ", name: "200Fly", style: "fly", distance: 200 },
      { name_jp: "100m個人メドレー", name: "100IM", style: "im", distance: 100 },
      { name_jp: "200m個人メドレー", name: "200IM", style: "im", distance: 200 },
      { name_jp: "400m個人メドレー", name: "400IM", style: "im", distance: 400 }
    ]

    styles.each do |style_data|
      Style.create!(style_data)
    end
  end

  def down
    drop_table :race_feedbacks
    drop_table :race_reviews
    drop_table :race_goals
    drop_table :milestone_reviews
    drop_table :milestones
    drop_table :objectives
    drop_table :attendance
    drop_table :attendance_events
    drop_table :records
    drop_table :styles
    drop_table :user_auths
    drop_table :users
    drop_table :announcements
  end
end 
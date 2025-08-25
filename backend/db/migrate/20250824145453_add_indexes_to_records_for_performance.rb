class AddIndexesToRecordsForPerformance < ActiveRecord::Migration[8.0]
  def change
    # === recordsテーブル ===
    # ユーザーIDとスタイルIDの複合インデックス（よく一緒に検索される）
    add_index :records, [:user_id, :style_id], name: 'index_records_on_user_id_and_style_id'
    
    # ユーザーIDとタイムの複合インデックス（ベストタイム取得用）
    add_index :records, [:user_id, :time], name: 'index_records_on_user_id_and_time'
    
    # スタイルIDとタイムの複合インデックス（種目別ランキング用）
    add_index :records, [:style_id, :time], name: 'index_records_on_style_id_and_time'
    
    # 3つのカラムの複合インデックス（最も効果的）
    add_index :records, [:user_id, :style_id, :time], name: 'index_records_on_user_style_time'
    
    # === attendanceテーブル ===
    # attendance_event_idでの検索が頻繁
    add_index :attendance, :attendance_event_id unless index_exists?(:attendance, :attendance_event_id)
    
    # ユーザーIDとステータスの複合インデックス（出席状況検索）
    add_index :attendance, [:user_id, :status], name: 'index_attendance_on_user_id_and_status'
    
    # === eventsテーブル ===
    # 既存のインデックスを確認してから追加
    unless index_exists?(:events, :date)
      add_index :events, :date
    end
    
    # 日付範囲検索の最適化
    add_index :events, [:date, :type], name: 'index_events_on_date_and_type'
    
    # === usersテーブル ===
    # 誕生日での検索最適化（EXTRACT関数用）
    add_index :users, "EXTRACT(month FROM birthday), EXTRACT(day FROM birthday)", name: 'index_users_on_birthday_month_day'
    
    # 世代とユーザータイプの複合インデックス
    add_index :users, [:generation, :user_type], name: 'index_users_on_generation_and_user_type'
    
    # === practice_timesテーブル ===
    # practice_log_idとuser_idの複合インデックス（既存のユニークインデックスを補完）
    add_index :practice_times, [:practice_log_id, :user_id], name: 'index_practice_times_on_practice_log_and_user'
    
    # === objectivesテーブル ===
    # attendance_event_idでの検索
    add_index :objectives, :attendance_event_id unless index_exists?(:objectives, :attendance_event_id)
    
    # === announcementsテーブル ===
    # 公開日時とアクティブフラグの複合インデックス
    add_index :announcements, [:published_at, :is_active], name: 'index_announcements_on_published_at_and_is_active'
  end
end

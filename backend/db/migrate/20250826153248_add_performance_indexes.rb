class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # ユーザー関連のインデックス
    add_index :users, [:user_type, :generation], name: 'index_users_on_user_type_and_generation'
    add_index :users, [:name, :generation], name: 'index_users_on_name_and_generation'
    
    # イベント関連のインデックス
    add_index :events, [:type, :date, :is_attendance], name: 'index_events_on_type_date_attendance'
    add_index :events, [:is_competition, :entry_status], name: 'index_events_on_competition_entry_status'
    
    # 出席関連のインデックス
    add_index :attendance, [:status, :created_at], name: 'index_attendance_on_status_and_created_at'
    add_index :attendance, [:attendance_event_id, :status], name: 'index_attendance_on_event_and_status'
    
    # 練習記録関連のインデックス
    add_index :practice_logs, [:style, :created_at], name: 'index_practice_logs_on_style_and_created_at'
    add_index :practice_times, [:user_id, :created_at], name: 'index_practice_times_on_user_and_created_at'
    add_index :practice_times, [:practice_log_id, :rep_number, :set_number], name: 'index_practice_times_on_log_rep_set'
    
    # 記録関連のインデックス
    add_index :records, [:user_id, :style_id, :created_at], name: 'index_records_on_user_style_created'
    add_index :records, [:attendance_event_id, :created_at], name: 'index_records_on_event_created'
    
    # 目標関連のインデックス
    add_index :objectives, [:user_id, :attendance_event_id], name: 'index_objectives_on_user_and_event'
    add_index :milestones, [:objective_id, :limit_date], name: 'index_milestones_on_objective_and_limit_date'
    
    # エントリー関連のインデックス
    add_index :entries, [:user_id, :attendance_event_id, :style_id], name: 'index_entries_on_user_event_style'
    add_index :entries, [:attendance_event_id, :entry_time], name: 'index_entries_on_event_and_time'
    
    # レース関連のインデックス
    add_index :race_goals, [:user_id, :attendance_event_id], name: 'index_race_goals_on_user_and_event'
    add_index :race_reviews, [:race_goal_id, :created_at], name: 'index_race_reviews_on_goal_and_created'
    
    # お知らせ関連のインデックス
    add_index :announcements, [:is_active, :published_at], name: 'index_announcements_on_active_and_published'
    
    # セッション関連のインデックス
    add_index :sessions, [:session_id, :updated_at], name: 'index_sessions_on_id_and_updated'
    
    # 部分インデックス（条件付きインデックス）
    add_index :users, :name, where: "user_type = 0", name: 'index_users_name_players_only'
    add_index :events, :date, where: "is_attendance = true", name: 'index_events_date_attendance_only'
    add_index :records, :time, where: "attendance_event_id IS NOT NULL", name: 'index_records_time_competition_only'
  end
end

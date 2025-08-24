class CreateNewEventsTable < ActiveRecord::Migration[8.0]
  def change
    # 既存のテーブルを削除（外部キー制約ごと）
    drop_table :events, if_exists: true
    drop_table :attendance_events, if_exists: true, force: :cascade
    
    # 新しい統合eventsテーブル作成（STI対応）
    create_table :events do |t|
      # 基本情報（全イベント共通）
      t.string :title, null: false
      t.date :date, null: false
      t.string :place
      t.text :note
      
      # STI用
      t.string :type, null: false, default: 'Event'
      
      # 出欠管理フラグ（水泳関連イベントのみtrue）
      t.boolean :is_attendance, default: false, null: false
      
      # AttendanceEvent用カラム
      t.integer :attendance_status, default: 0
      t.boolean :is_competition, default: false
      
      # CompetitionEvent用カラム
      t.integer :entry_status, default: 0
      
      t.timestamps
    end
    
    # インデックス追加
    add_index :events, :type
    add_index :events, [:type, :date]
    add_index :events, :date
    add_index :events, :is_attendance
    add_index :events, :is_competition
    
    # 外部キー制約を再作成
    add_foreign_key :attendance, :events, column: :attendance_event_id
    add_foreign_key :objectives, :events, column: :attendance_event_id
    add_foreign_key :practice_logs, :events, column: :attendance_event_id
    add_foreign_key :race_goals, :events, column: :attendance_event_id
    add_foreign_key :records, :events, column: :attendance_event_id
    add_foreign_key :entries, :events, column: :attendance_event_id
  end
end

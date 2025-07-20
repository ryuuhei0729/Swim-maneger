class CreateNewEventsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :new_events do |t|
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
    add_index :new_events, :type
    add_index :new_events, [:type, :date]
    add_index :new_events, :date
    add_index :new_events, :is_attendance
    add_index :new_events, :is_competition
  end
end

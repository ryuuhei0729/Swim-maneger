class CreatePracticeTables < ActiveRecord::Migration[7.0]
  def up
    # 練習ログテーブル
    create_table :practice_logs do |t|
      t.references :attendance_event, null: false, foreign_key: true
      t.json :tags
      t.string :style
      t.integer :rep_count, null: false
      t.integer :set_count, null: false
      t.integer :distance, null: false
      t.decimal :circle, precision: 10, scale: 2, null: false
      t.text :note
      t.timestamps
    end

    # 練習タイムテーブル
    create_table :practice_times do |t|
      t.references :user, null: false, foreign_key: true
      t.references :practice_log, null: false, foreign_key: true
      t.integer :rep_number, null: false
      t.integer :set_number, null: false
      t.decimal :time, precision: 10, scale: 2, null: false
      t.timestamps
    end

    # インデックス
    add_index :practice_logs, :style
    add_index :practice_times, [ :practice_log_id, :user_id, :rep_number, :set_number ], unique: true, name: 'index_practice_times_on_unique_combination'
  end

  def down
    drop_table :practice_times
    drop_table :practice_logs
  end
end

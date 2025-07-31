class CreateSplitTimes < ActiveRecord::Migration[8.0]
  def up
    create_table :split_times do |t|
      t.references :record, null: false, foreign_key: true
      t.references :race_goal, null: false, foreign_key: true
      t.integer :distance, null: false
      t.decimal :split_time, precision: 10, scale: 2, null: false

      t.timestamps
    end

    # entriesテーブルのentry_timeのprecisionを8から10に統一
    change_column :entries, :entry_time, :decimal, precision: 10, scale: 2, null: false
  end

  def down
    drop_table :split_times
    
    # entriesテーブルのentry_timeのprecisionを10から8に戻す
    change_column :entries, :entry_time, :decimal, precision: 8, scale: 2, null: false
  end
end

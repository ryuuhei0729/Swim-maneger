class CreateEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :entries do |t|
      t.integer :user_id, null: false
      t.integer :attendance_event_id, null: false
      t.integer :style_id, null: false
      t.decimal :entry_time, precision: 8, scale: 2, null: false
      t.text :note

      t.timestamps
    end

    add_foreign_key :entries, :users, column: :user_id
    add_foreign_key :entries, :attendance_events, column: :attendance_event_id
    add_foreign_key :entries, :styles, column: :style_id

    add_index :entries, :user_id
    add_index :entries, :attendance_event_id
    add_index :entries, :style_id
    add_index :entries, [:attendance_event_id, :user_id, :style_id], unique: true, name: 'index_entries_unique_combination'
  end
end

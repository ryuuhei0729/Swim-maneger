class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.boolean :is_active, default: true, null: false
      t.datetime :published_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false

      t.timestamps
    end
    
    add_index :announcements, :published_at
    add_index :announcements, :is_active
  end
end

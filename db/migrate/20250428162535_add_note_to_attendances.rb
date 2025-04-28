class AddNoteToattendance < ActiveRecord::Migration[8.0]
  def change
    add_column :attendance, :note, :text
  end
end

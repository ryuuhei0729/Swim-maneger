class AddNoteToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :attendances, :note, :text
  end
end

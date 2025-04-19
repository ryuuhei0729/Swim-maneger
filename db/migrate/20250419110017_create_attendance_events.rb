class CreateAttendanceEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_events do |t|
      t.string :title
      t.date :date
      t.text :note

      t.timestamps
    end
  end
end

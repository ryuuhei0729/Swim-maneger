class AddPlaceToAttendanceEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :attendance_events, :place, :string
  end
end 
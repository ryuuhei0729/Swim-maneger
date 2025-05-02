class AddCompetitionToAttendanceEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :attendance_events, :competition, :boolean, default: false, null: false
  end
end

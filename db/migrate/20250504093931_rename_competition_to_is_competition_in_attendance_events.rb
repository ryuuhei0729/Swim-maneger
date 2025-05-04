class RenameCompetitionToIsCompetitionInAttendanceEvents < ActiveRecord::Migration[8.0]
  def change
    rename_column :attendance_events, :competition, :is_competition
  end
end

class FixAttendanceIndexNames < ActiveRecord::Migration[8.0]
  def change
    # インデックス名を正しい名前に修正
    rename_index :attendances, 'index_attendance_on_event_and_status', 'index_attendances_on_event_and_status'
  end
end

class UpdateAttendanceStatusToOther < ActiveRecord::Migration[7.1]
  def up
    Attendance.where(status: 'late').update_all(status: 'other')
  end

  def down
    # 元に戻す必要がある場合は、ここにロジックを追加
  end
end

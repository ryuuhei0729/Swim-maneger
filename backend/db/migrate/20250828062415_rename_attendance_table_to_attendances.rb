class RenameAttendanceTableToAttendances < ActiveRecord::Migration[8.0]
  def change
    # テーブル名を attendance から attendances に変更
    rename_table :attendance, :attendances
  end
end

class AddStatusConstraintToAttendance < ActiveRecord::Migration[7.1]
  def up
    execute("
      ALTER TABLE attendance
      DROP CONSTRAINT IF EXISTS check_status;
    ")
  end

  def down
    execute("
      ALTER TABLE attendance
      ADD CONSTRAINT check_status
      CHECK (status IN ('present', 'absent', 'other'));
    ")
  end
end
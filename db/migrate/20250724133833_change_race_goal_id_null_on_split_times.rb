class ChangeRaceGoalIdNullOnSplitTimes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :split_times, :race_goal_id, true
  end
end

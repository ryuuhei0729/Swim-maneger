class AddGenderConstraintToUsers < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT check_gender
      CHECK (gender IN ('male', 'female'));
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT check_gender;
    SQL
  end
end

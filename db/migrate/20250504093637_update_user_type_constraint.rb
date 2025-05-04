class UpdateUserTypeConstraint < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS check_user_type;

      ALTER TABLE users
      ADD CONSTRAINT check_user_type
      CHECK (user_type IN ('player', 'coach', 'director', 'manager'));
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT check_user_type;
    SQL
  end
end

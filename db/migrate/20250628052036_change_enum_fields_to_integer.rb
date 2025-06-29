class ChangeEnumFieldsToInteger < ActiveRecord::Migration[7.0]
  def up
    # 一時的なカラムを作成
    add_column :users, :gender_temp, :integer
    add_column :users, :user_type_temp, :integer
    add_column :attendance, :status_temp, :integer

    # データを変換
    execute <<-SQL
      UPDATE users SET 
        gender_temp = CASE gender
          WHEN 'male' THEN 0
          WHEN 'female' THEN 1
          WHEN 'other' THEN 2
          ELSE 0
        END,
        user_type_temp = CASE user_type
          WHEN 'player' THEN 0
          WHEN 'manager' THEN 1
          WHEN 'coach' THEN 2
          WHEN 'director' THEN 3
          ELSE 0
        END;
    SQL

    execute <<-SQL
      UPDATE attendance SET 
        status_temp = CASE status
          WHEN 'present' THEN 0
          WHEN 'absent' THEN 1
          WHEN 'other' THEN 2
          ELSE 1
        END;
    SQL

    # 古いカラムを削除
    remove_column :users, :gender
    remove_column :users, :user_type
    remove_column :attendance, :status

    # 新しいカラムをリネーム
    rename_column :users, :gender_temp, :gender
    rename_column :users, :user_type_temp, :user_type
    rename_column :attendance, :status_temp, :status

    # 制約を追加
    add_check_constraint :users, "gender IN (0, 1, 2)", name: "check_gender"
    add_check_constraint :users, "user_type IN (0, 1, 2, 3)", name: "check_user_type"
    add_check_constraint :attendance, "status IN (0, 1, 2)", name: "check_status"
  end

  def down
    # 一時的なカラムを作成
    add_column :users, :gender_temp, :string
    add_column :users, :user_type_temp, :string
    add_column :attendance, :status_temp, :string

    # データを変換（逆変換）
    execute <<-SQL
      UPDATE users SET 
        gender_temp = CASE gender
          WHEN 0 THEN 'male'
          WHEN 1 THEN 'female'
          WHEN 2 THEN 'other'
          ELSE 'male'
        END,
        user_type_temp = CASE user_type
          WHEN 0 THEN 'player'
          WHEN 1 THEN 'manager'
          WHEN 2 THEN 'coach'
          WHEN 3 THEN 'director'
          ELSE 'player'
        END;
    SQL

    execute <<-SQL
      UPDATE attendance SET 
        status_temp = CASE status
          WHEN 0 THEN 'present'
          WHEN 1 THEN 'absent'
          WHEN 2 THEN 'other'
          ELSE 'present'
        END;
    SQL

    # 古いカラムを削除
    remove_column :users, :gender
    remove_column :users, :user_type
    remove_column :attendance, :status

    # 新しいカラムをリネーム
    rename_column :users, :gender_temp, :gender
    rename_column :users, :user_type_temp, :user_type
    rename_column :attendance, :status_temp, :status

    # 制約を追加
    add_check_constraint :users, "gender IN ('male', 'female', 'other')", name: "check_gender"
    add_check_constraint :users, "user_type IN ('director', 'coach', 'player', 'manager')", name: "check_user_type"
    add_check_constraint :attendance, "status IN ('present', 'absent', 'other')", name: "check_status"
  end
end

class ChangeStyleFieldToInteger < ActiveRecord::Migration[7.0]
  def up
    # 一時的なカラムを作成
    add_column :styles, :style_temp, :integer

    # データを変換
    execute <<-SQL
      UPDATE styles SET 
        style_temp = CASE style
          WHEN 'fr' THEN 0
          WHEN 'br' THEN 1
          WHEN 'ba' THEN 2
          WHEN 'fly' THEN 3
          WHEN 'im' THEN 4
          ELSE 0
        END;
    SQL

    # 古いカラムを削除
    remove_column :styles, :style

    # 新しいカラムをリネーム
    rename_column :styles, :style_temp, :style

    # 制約を追加
    add_check_constraint :styles, "style IN (0, 1, 2, 3, 4)", name: "check_style"
  end

  def down
    # 一時的なカラムを作成
    add_column :styles, :style_temp, :string

    # データを変換（逆変換）
    execute <<-SQL
      UPDATE styles SET 
        style_temp = CASE style
          WHEN 0 THEN 'fr'
          WHEN 1 THEN 'br'
          WHEN 2 THEN 'ba'
          WHEN 3 THEN 'fly'
          WHEN 4 THEN 'im'
          ELSE 'fr'
        END;
    SQL

    # 古いカラムを削除
    remove_column :styles, :style

    # 新しいカラムをリネーム
    rename_column :styles, :style_temp, :style

    # 制約を追加
    add_check_constraint :styles, "style IN ('fr', 'br', 'ba', 'fly', 'im')", name: "check_style"
  end
end

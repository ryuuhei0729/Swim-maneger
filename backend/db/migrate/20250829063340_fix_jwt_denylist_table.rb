class FixJwtDenylistTable < ActiveRecord::Migration[8.0]
  def up
    # 既存のテーブルが存在する場合は削除
    if table_exists?(:jwt_denylists)
      drop_table :jwt_denylists
    end
    
    # 正しいテーブルを作成
    create_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.timestamps
    end
    
    add_index :jwt_denylists, :jti, unique: true
    add_index :jwt_denylists, :exp
  end

  def down
    drop_table :jwt_denylists if table_exists?(:jwt_denylists)
  end
end

class ChangeUserIdNullableInUserAuths < ActiveRecord::Migration[8.0]
  def change
    change_column_null :user_auths, :user_id, true
  end
end

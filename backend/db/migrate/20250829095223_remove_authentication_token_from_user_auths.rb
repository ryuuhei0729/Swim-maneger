class RemoveAuthenticationTokenFromUserAuths < ActiveRecord::Migration[8.0]
  def change
    # authentication_tokenカラムとインデックスを削除
    remove_index :user_auths, :authentication_token, if_exists: true
    remove_column :user_auths, :authentication_token, :string
  end
end

class AddAuthenticationTokenToUserAuths < ActiveRecord::Migration[8.0]
  def change
    add_column :user_auths, :authentication_token, :string
    add_index :user_auths, :authentication_token, unique: true
  end
end

class RenameUsersToUserAuths < ActiveRecord::Migration[8.0]
  def change
    rename_table :users, :user_auths
  end
end

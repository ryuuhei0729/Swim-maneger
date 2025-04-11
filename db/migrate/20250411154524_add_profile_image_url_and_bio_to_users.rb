class AddProfileImageUrlAndBioToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_image_url, :string, default: ""
    add_column :users, :bio, :text, default: ""
  end
end

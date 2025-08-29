class CreateJwtDenylist < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_denylists do |t|
      t.timestamps
    end
  end
end

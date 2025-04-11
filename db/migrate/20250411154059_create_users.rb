class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.integer :generation, null: false
      t.string :name, null: false
      t.string :gender, null: false
      t.date :birthday, null: false
      t.string :user_type, null: false

      t.timestamps
    end
  end
end

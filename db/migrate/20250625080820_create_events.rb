class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title
      t.date :date
      t.string :place
      t.text :note

      t.timestamps
    end
  end
end

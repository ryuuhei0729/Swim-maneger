class Createattendance < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance do |t|
      t.references :user, null: false, foreign_key: true
      t.references :attendance_event, null: false, foreign_key: true
      t.string :status
      t.text :note

      t.timestamps
    end
  end
end

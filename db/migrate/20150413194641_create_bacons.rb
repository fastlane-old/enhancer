class CreateBacons < ActiveRecord::Migration
  def change
    create_table :bacons do |t|
      t.string :action_name
      t.date :launch_date
      t.integer :launches
      t.integer :number_errors

      t.timestamps null: false
    end
  end
end

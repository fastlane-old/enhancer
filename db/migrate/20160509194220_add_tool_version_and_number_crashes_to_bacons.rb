class AddToolVersionAndNumberCrashesToBacons < ActiveRecord::Migration
  def up
    add_column :bacons, :tool_version, :string, default: 'unknown', null: false, limit: 50
    add_column :bacons, :number_crashes, :integer, default: 0, null: false

    change_column :bacons, :number_errors, :integer, default: 0, null: false
    change_column :bacons, :launches, :integer, default: 0, null: false
    change_column :bacons, :action_name, :string, null: false, limit: 255
    change_column :bacons, :launch_date, :date, null: false
  end

  def down
    remove_column :bacons, :tool_version, :string, limit: nil
    remove_column :bacons, :number_crashes, :integer

    change_column :bacons, :number_errors, :integer, default: nil, null: true
    change_column :bacons, :launches, :integer, default: nil, null: true
    change_column :bacons, :action_name, :string, null: true, limit: nil
    change_column :bacons, :launch_date, :date, null: true
  end
end

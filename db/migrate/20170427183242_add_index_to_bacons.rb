class AddIndexToBacons < ActiveRecord::Migration
  def change
    add_index :bacons, [:action_name, :launch_date, :tool_version]
  end
end

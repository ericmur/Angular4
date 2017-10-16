class ChangeIndexOnDevices < ActiveRecord::Migration
  def change
    remove_index :devices, ["device_uuid"]
    remove_index :devices, ["device_uuid", "user_id"]
    add_index :devices, ["device_uuid", "user_id"], :unique => true
  end
end

class CreatePushDevices < ActiveRecord::Migration
  def change
    create_table :push_devices do |t|
      t.string :device_uuid
      t.string :device_token

      t.timestamps null: false
    end

    add_index :push_devices, ["device_uuid", "device_token"], :unique => true
  end
end

class AddDevicesForUsers < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.string :device_uuid
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.integer :user_id
    end

    add_index :devices, :device_uuid, :unique => true
    add_index :devices, [:device_uuid, :user_id]
  end
end

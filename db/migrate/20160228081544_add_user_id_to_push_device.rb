class AddUserIdToPushDevice < ActiveRecord::Migration
  def change
    add_reference :push_devices, :user, :index => true
  end
end

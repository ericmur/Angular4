class AddIndextoMessageUsers < ActiveRecord::Migration
  def change
    add_index :message_users, :receiver_type
    add_index :message_users, :receiver_id
  end
end

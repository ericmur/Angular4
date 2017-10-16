class AddNotifyAtToMessageUsers < ActiveRecord::Migration
  def change
    add_column :message_users, :notify_at, :datetime
  end
end

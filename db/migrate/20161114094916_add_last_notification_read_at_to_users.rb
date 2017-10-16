class AddLastNotificationReadAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_time_notifications_read_at, :timestamp
  end
end

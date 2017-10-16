class AddLastMessagesReadAtToChatsUsersRelations < ActiveRecord::Migration
  def change
    add_column :chats_users_relations, :last_time_messages_read_at, :timestamp
  end
end

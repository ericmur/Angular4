class AddIsSupportChatToChat < ActiveRecord::Migration
  def change
    add_column :chats, :is_support_chat, :boolean, :default => false
  end
end

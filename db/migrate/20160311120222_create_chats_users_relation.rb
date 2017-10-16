class CreateChatsUsersRelation < ActiveRecord::Migration
  def change
    create_table :chats_users_relations do |t|
      t.belongs_to :user
      t.belongs_to :chat
      t.timestamps null: false
    end
  end
end

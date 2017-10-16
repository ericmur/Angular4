class ChangeChatUserRelationModel < ActiveRecord::Migration
  def change
    remove_reference :chats_users_relations, :user

    add_reference :chats_users_relations, :chatable, :polymorphic => true, :index => true
  end
end

class AddMessageIdToChatDocument < ActiveRecord::Migration
  def change
    add_column :chat_documents, :message_id, :integer
    add_index  :chat_documents, :message_id
  end
end

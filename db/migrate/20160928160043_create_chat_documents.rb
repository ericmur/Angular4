class CreateChatDocuments < ActiveRecord::Migration
  def change
    create_table :chat_documents do |t|
      t.integer :chat_id
      t.integer :document_id

      t.timestamps null: false
    end
    add_index :chat_documents, :chat_id
    add_index :chat_documents, :document_id
  end
end

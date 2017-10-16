class AddResponseGroupToDocytBotSessionDocuments < ActiveRecord::Migration
  def change
    add_column :docyt_bot_session_documents, :response_group, :string
  end
end

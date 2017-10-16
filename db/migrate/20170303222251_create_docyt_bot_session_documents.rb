class CreateDocytBotSessionDocuments < ActiveRecord::Migration
  def change
    create_table :docyt_bot_session_documents do |t|
      t.integer :docyt_bot_session_id
      t.integer :document_id
      t.timestamps null: false
    end
  end
end

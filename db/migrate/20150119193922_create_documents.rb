class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.integer :consumer_id
      t.integer :standard_document_id
      t.integer :group_user_id
      t.boolean :current, default: true
      t.timestamps
    end
    add_index :documents, [:consumer_id, :standard_document_id]
    add_index :documents, [:group_user_id, :consumer_id]
    add_index :documents, [:id, :consumer_id]
  end

  
end

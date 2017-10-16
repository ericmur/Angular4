class CreateWorkflowStandardDocuments < ActiveRecord::Migration
  def change
    create_table :workflow_standard_documents do |t|
      t.integer :workflow_id
      t.integer :standard_document_id

      t.timestamps null: false
    end
    add_index :workflow_standard_documents, :workflow_id
    add_index :workflow_standard_documents, :standard_document_id
  end
end

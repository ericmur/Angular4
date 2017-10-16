class CreateWorkflowDocumentUploads < ActiveRecord::Migration
  def change
    create_table :workflow_document_uploads do |t|
      t.integer :user_id, index: true
      t.integer :document_id, index: true
      t.integer :workflow_standard_document_id, index: { name: 'index_workflow_standard_document_id'}

      t.timestamps null: false
    end
  end
end

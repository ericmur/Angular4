class ChangeWorkflowStandardDocuments < ActiveRecord::Migration
  def change
    remove_column :workflow_standard_documents, :workflow_id

    add_column :workflow_standard_documents, :ownerable_type, :string
    add_column :workflow_standard_documents, :ownerable_id, :integer
  end
end

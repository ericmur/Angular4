class AddExpectedDocumentsCountToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :expected_documents_count, :integer
  end
end

class AddSuggestedCategoryToDocument < ActiveRecord::Migration
  def change
    add_reference :documents, :suggested_standard_document, :references => :standard_document
    add_index :documents, [:consumer_id, :suggested_standard_document_id], :name => "auto_categorization_index"
  end
end

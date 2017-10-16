class RemoveStandardDocumentFieldIdFromValue < ActiveRecord::Migration
  def change
    remove_column :document_field_values, :standard_document_field_id
  end
end

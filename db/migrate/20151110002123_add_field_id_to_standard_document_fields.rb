class AddFieldIdToStandardDocumentFields < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :field_id, :integer
    add_column :document_field_values, :local_standard_document_field_id, :integer
    remove_index :document_field_values, :name => "document_field_values_index"
    add_index :document_field_values, [:document_id, :local_standard_document_field_id], :name => "document_field_values_index"
  end
end

class AddDataTypesValuesToStandardDocumentFields < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :data_type_values, :text
  end
end

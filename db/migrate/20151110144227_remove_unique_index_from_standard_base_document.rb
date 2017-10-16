class RemoveUniqueIndexFromStandardBaseDocument < ActiveRecord::Migration
  def change
    remove_index :standard_document_fields, name: "index_standard_document_fields_on_standard_document_id_and_name"
  end
end

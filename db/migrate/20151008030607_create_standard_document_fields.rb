class CreateStandardDocumentFields < ActiveRecord::Migration
  def change
    create_table :standard_document_fields do |t|
      t.integer :standard_document_id
      t.string  :name
      t.string  :data_type
    end

    add_index :standard_document_fields, [:standard_document_id, :name], :unique => true
  end
end

class CreateDocumentFieldValues < ActiveRecord::Migration
  def change
    create_table :document_field_values do |t|
      t.integer :standard_document_field_id
      t.integer :document_id
      t.text  :encrypted_value
      t.timestamps null: false
    end

    add_index :document_field_values, [:standard_document_field_id, :document_id], :unique => true, :name => "document_field_values_index"
  end
end

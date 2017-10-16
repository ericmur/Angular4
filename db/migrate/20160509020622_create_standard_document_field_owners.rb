class CreateStandardDocumentFieldOwners < ActiveRecord::Migration
  def change
    create_table :standard_document_field_owners do |t|
      t.references :standard_document_field
      t.references :owner, :polymorphic => true, :index => true
      t.timestamps null: false
    end
    add_index :standard_document_field_owners, [:standard_document_field_id, :owner_id, :owner_type], :unique => true, :name => "document_field_owners_index"
    add_index :standard_base_document_owners, [:standard_base_document_id, :owner_id, :owner_type], :unique => true, :name => "base_document_owners_index"
    
    add_column :standard_document_fields, :created_by_user_id, :integer
    add_foreign_key :standard_document_fields, :users, :column => :created_by_user_id
  end
end

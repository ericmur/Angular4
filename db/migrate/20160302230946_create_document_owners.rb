class CreateDocumentOwners < ActiveRecord::Migration
  def change
    create_table :document_owners do |t|
      t.references :document
      t.integer :owner_id
      t.string  :owner_type
      t.timestamps null: false
    end

    add_index :document_owners, [:owner_id, :owner_type]
    add_index :document_owners, [:document_id, :owner_id, :owner_type], unique: true, name: "document_owners_unique_idx"

    remove_column :documents, :group_user_id, :integer
    remove_column :standard_base_documents, :group_user_id, :integer

    add_column :standard_base_documents, :created_for_id, :integer
    add_column :standard_base_documents, :created_for_type, :string

    add_index :standard_base_documents, [:created_for_id, :created_for_type], name: "standard_base_documents_created_for_idx"
  end
end

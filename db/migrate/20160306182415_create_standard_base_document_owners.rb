class CreateStandardBaseDocumentOwners < ActiveRecord::Migration
  def change
    create_table :standard_base_document_owners do |t|
      t.references :standard_base_document
      t.references :owner, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end

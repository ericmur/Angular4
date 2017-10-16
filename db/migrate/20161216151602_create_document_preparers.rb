class CreateDocumentPreparers < ActiveRecord::Migration
  def change
    create_table :document_preparers do |t|
      t.integer :preparer_id
      t.integer :document_id

      t.timestamps null: false
    end
    add_index :document_preparers, :preparer_id
    add_index :document_preparers, :document_id
  end
end

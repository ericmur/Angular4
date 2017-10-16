class CreateDocumentPermissions < ActiveRecord::Migration
  def change
    create_table :document_permissions do |t|
      t.references :user, index: true, foreign_key: true
      t.references :document, index: true, foreign_key: true
      t.string :value
      t.string :user_type

      t.timestamps null: false
    end
  end
end

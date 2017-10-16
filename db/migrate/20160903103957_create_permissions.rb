class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :standard_base_document, index: true, foreign_key: true
      t.references :folder_structure_owner, polymorphic: true
      t.references :user, index: true, foreign_key: true
      t.string :value

      t.timestamps null: false
    end
    add_index :permissions, [:folder_structure_owner_id, :folder_structure_owner_type], name: 'folder_structure_owner_idx'
    add_index :permissions, :value
  end
end

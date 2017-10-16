class CreateUserFolderSettings < ActiveRecord::Migration
  def change
    create_table :user_folder_settings do |t|
      t.references :user, index: true, foreign_key: true
      t.references :folder_owner, polymorphic: true
      t.integer :standard_base_document_id, index: true
      t.boolean :displayed, default: true, index: true

      t.timestamps null: false
    end
    add_index(:user_folder_settings, [:folder_owner_id, :folder_owner_type], name: 'user_setting_folders_owner_idx')
    add_index(:user_folder_settings, [:user_id, :standard_base_document_id], name: 'user_setting_folders_idx')
  end
end

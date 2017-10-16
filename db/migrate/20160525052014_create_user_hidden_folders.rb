class CreateUserHiddenFolders < ActiveRecord::Migration
  def change
    create_table :user_hidden_folders do |t|
      t.integer :standard_base_document_id, index: true
      t.references :user, index: true, foreign_key: true
      t.timestamps null: false
    end
    add_index(:user_hidden_folders, [:user_id, :standard_base_document_id], name: 'user_hidden_folders_idx')
  end
end

class AddOriginalFileToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :original_file_name, :string
    add_column :documents, :original_file_key, :string
    add_column :documents, :storage_size, :integer, default: 0
    add_column :documents, :state, :string
  end
end

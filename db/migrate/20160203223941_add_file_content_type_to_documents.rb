class AddFileContentTypeToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :file_content_type, :string
  end
end

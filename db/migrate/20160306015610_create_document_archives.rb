class CreateDocumentArchives < ActiveRecord::Migration
  def change
    create_table :document_archives do |t|
      t.integer :suggested_standard_document_id
      t.integer :rejected_at
      t.datetime :suggested_at
      t.integer :consumer_id
      t.string  :source
      t.string  :file_content_type
      t.string  :cloud_service_full_path
      t.string  :original_file_name
      t.timestamps null: false
    end

    remove_column :documents, :rejected_at, :datetime
  end
end

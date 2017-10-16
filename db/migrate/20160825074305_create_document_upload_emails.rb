class CreateDocumentUploadEmails < ActiveRecord::Migration
  def change
    create_table :document_upload_emails do |t|
      t.integer :standard_document_id
      t.integer :consumer_id, index: true
      t.string :email, index: true, unique: true

      t.timestamps null: false
    end

    add_index :document_upload_emails, [:consumer_id, :standard_document_id], unique: true, name: "document_upload_emails_consumer_idx"
  end
end

class AddConsumerEmailToDocumentUploadEmails < ActiveRecord::Migration
  def change
    add_column :document_upload_emails, :consumer_email, :string
  end
end

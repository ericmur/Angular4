class AddBusinessIdToDocumentUploadEmails < ActiveRecord::Migration
  def change
    add_column :document_upload_emails, :business_id, :integer
  end
end

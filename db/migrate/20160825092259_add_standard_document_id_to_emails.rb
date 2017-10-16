class AddStandardDocumentIdToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :standard_document_id, :integer
  end
end

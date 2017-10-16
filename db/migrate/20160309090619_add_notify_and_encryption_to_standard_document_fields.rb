class AddNotifyAndEncryptionToStandardDocumentFields < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :notify, :boolean, default: false
    add_column :standard_document_fields, :encryption, :boolean, default: false
  end
end

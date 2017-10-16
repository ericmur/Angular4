class AddSpeechFieldsToDocumentField < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :speech_type, :string
    add_column :standard_document_fields, :speech_name, :string
  end
end

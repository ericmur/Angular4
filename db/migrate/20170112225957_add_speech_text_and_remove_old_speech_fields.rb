class AddSpeechTextAndRemoveOldSpeechFields < ActiveRecord::Migration
  def change
    remove_column :standard_document_fields, :speech_type, :string
    remove_column :standard_document_fields, :speech_name, :string
    add_column :standard_document_fields, :speech_text, :text
  end
end

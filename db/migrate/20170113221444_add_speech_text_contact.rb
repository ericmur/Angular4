class AddSpeechTextContact < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :speech_text_contact, :text
  end
end

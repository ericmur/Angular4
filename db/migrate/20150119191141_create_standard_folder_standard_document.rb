class CreateStandardFolderStandardDocument < ActiveRecord::Migration
  def change
    create_table :standard_folder_standard_documents do |t|
      t.integer  :standard_folder_id
      t.integer  :standard_base_document_id
      t.integer  :rank
    end
  end
end

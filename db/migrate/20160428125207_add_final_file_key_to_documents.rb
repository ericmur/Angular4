class AddFinalFileKeyToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :final_file_key, :string
  end
end

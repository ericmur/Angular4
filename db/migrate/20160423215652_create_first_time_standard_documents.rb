class CreateFirstTimeStandardDocuments < ActiveRecord::Migration
  def change
    create_table :first_time_standard_documents do |t|
      t.references :standard_document
      t.references :consumer_account_type
      t.timestamps null: false
      t.index [:consumer_account_type_id, :standard_document_id], :name => "first_time_docs_index"
    end
  end
end

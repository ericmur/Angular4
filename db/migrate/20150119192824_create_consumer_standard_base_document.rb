class CreateConsumerStandardBaseDocument < ActiveRecord::Migration
  def change
    create_table :consumer_standard_base_documents do |t|
      t.integer :consumer_id
      t.integer :standard_base_document_id
      t.timestamps
    end
    add_index :consumer_standard_base_documents, :standard_base_document_id, :name => "consumer_documents_index"
  end
end

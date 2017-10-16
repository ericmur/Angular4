class FixIndexOnConsumerStandardDoc < ActiveRecord::Migration
  def change
    remove_index :consumer_standard_base_documents, name: "consumer_documents_index"
    add_index :consumer_standard_base_documents, [:standard_base_document_id, :consumer_id], name: "consumer_documents_index"
  end
end

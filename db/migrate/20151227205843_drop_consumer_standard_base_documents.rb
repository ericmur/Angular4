class DropConsumerStandardBaseDocuments < ActiveRecord::Migration
  def change
    drop_table :consumer_standard_base_documents
  end
end

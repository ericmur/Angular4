class AddConsumerIdToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :consumer_id, :integer
    add_index :standard_base_documents, :consumer_id
  end
end

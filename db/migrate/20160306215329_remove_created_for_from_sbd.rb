class RemoveCreatedForFromSbd < ActiveRecord::Migration
  def change
    remove_column :standard_base_documents, :created_for_id, :integer
    remove_column :standard_base_documents, :created_for_type, :string
  end
end

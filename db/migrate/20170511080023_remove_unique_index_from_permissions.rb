class RemoveUniqueIndexFromPermissions < ActiveRecord::Migration
  def change
    remove_index :permissions, column: :standard_base_document_id
  end
end

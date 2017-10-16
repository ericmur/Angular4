class ChangeTotalStorageSizeType < ActiveRecord::Migration
  def change
    change_column :users, :total_storage_size, :integer, limit: 8
  end
end

class AddStorageLimitToUsers < ActiveRecord::Migration
  def change
    add_column :users, :total_storage_size, :integer, default: 0
    add_column :users, :total_pages_count, :integer, default: 0
    add_column :users, :limit_storage_size, :integer, default: 5368709120, :limit => 8
    add_column :users, :limit_pages_count, :integer, default: 1000
  end
end

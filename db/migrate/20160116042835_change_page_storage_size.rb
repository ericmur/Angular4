class ChangePageStorageSize < ActiveRecord::Migration
  def change
    change_column :pages, :storage_size, :integer, :limit => 8, :default => 0
  end
end

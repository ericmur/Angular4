class AddStorageSizeToPages < ActiveRecord::Migration
  def change
    add_column :pages, :storage_size, :integer, default: 0
  end
end

class RemoveCntFromSymmetricKey < ActiveRecord::Migration
  def change
    remove_column :symmetric_keys, :cnt, :integer, :default => 1
  end
end

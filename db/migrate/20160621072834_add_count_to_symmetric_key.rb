class AddCountToSymmetricKey < ActiveRecord::Migration
  def change
    add_column :symmetric_keys, :cnt, :integer, :default => 1
  end
end

class AddSourceToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :source, :string, :default => 'Photos'
  end
end

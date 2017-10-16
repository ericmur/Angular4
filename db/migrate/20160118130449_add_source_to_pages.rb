class AddSourceToPages < ActiveRecord::Migration
  def change
    add_column :pages, :source, :string, :default => 'Camera'
  end
end

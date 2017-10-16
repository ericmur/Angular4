class AddVersionToPages < ActiveRecord::Migration
  def change
    add_column :pages, :version, :integer, default: 0
  end
end

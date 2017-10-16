class AddDefaultToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :default, :boolean
  end
end

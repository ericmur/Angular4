class AddIconNamesToStandardBaseDocument < ActiveRecord::Migration
  def change
    remove_column :standard_base_documents, :icon_name
    add_column :standard_base_documents, :icon_name_1x, :string
    add_column :standard_base_documents, :icon_name_2x, :string
    add_column :standard_base_documents, :icon_name_3x, :string
  end
end

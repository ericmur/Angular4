class AddIconNameToStandardBaseDocuments < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :icon_name, :string
  end
end

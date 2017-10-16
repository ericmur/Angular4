class AddPrimaryNameToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :primary_name, :string
  end
end

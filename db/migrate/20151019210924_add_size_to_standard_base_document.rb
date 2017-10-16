class AddSizeToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :size, :string
  end
end

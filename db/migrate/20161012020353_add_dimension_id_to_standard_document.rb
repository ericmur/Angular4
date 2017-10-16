class AddDimensionIdToStandardDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :dimension_id, :integer
  end
end

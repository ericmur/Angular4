class AddDescriptionToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column(:standard_base_documents, :description, :string)
  end
end

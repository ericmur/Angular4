class AddClearValueToDocumentFieldValues < ActiveRecord::Migration
  def change
    add_column :document_field_values, :value, :text
  end
end

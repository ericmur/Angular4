class AddSuggestionsAttributeToField < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :suggestions, :boolean
  end
end

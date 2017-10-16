class AddFieldPrimaryDescriptor < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :primary_descriptor, :boolean, :default => false
  end
end

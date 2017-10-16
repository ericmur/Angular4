class AddMinAndMaxYearToStandardDocumentFields < ActiveRecord::Migration
  def change
    add_column :standard_document_fields, :min_year, :integer
    add_column :standard_document_fields, :max_year, :integer
    add_column :standard_document_fields, :type, :string
  end
end

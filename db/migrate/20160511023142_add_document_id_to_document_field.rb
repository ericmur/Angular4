class AddDocumentIdToDocumentField < ActiveRecord::Migration
  def change
    add_reference :standard_document_fields, :document
  end
end

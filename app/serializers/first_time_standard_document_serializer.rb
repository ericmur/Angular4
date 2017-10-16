class FirstTimeStandardDocumentSerializer < ActiveModel::Serializer
  attributes :standard_document_id, :name

  def name
    StandardDocument.where(:id => object.standard_document_id).first.name
  end
end

require 'active_support/concern'

module SerializerStandardFields
  extend ActiveSupport::Concern

  def standard_document_fields
    if object.standard_document
      doc_fields = object.standard_document.standard_document_fields + object.document_fields
      ActiveModel::ArraySerializer.new(doc_fields, :each_serializer => BaseDocumentFieldSerializer, :scope => { current_user: current_user, :document_id => object.id }, :root => false)
    else
      []
    end
  end

end

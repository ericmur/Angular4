class Api::Mobile::V2::DocumentDetailSecureSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  attributes :id, :symmetric_key, :standard_document_fields
  delegate :current_user, to: :scope

  def standard_document_fields
    if object.standard_document
      doc_fields = object.standard_document.standard_document_fields.where(encryption: true) + object.document_fields.where(encryption: true)
      ActiveModel::ArraySerializer.new(doc_fields,
        each_serializer: BaseDocumentFieldSerializer,
        scope: { current_user: current_user, document_id: object.id },
        root: false)
    else
      []
    end
  end
end
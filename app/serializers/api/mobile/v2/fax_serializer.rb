class Api::Mobile::V2::FaxSerializer < ActiveModel::Serializer
  attributes :id, :document_id, :sender_id, :status, :fax_number, :created_at, :pages_count, :document, :status_message, :document_title

  def document
    ::Api::Mobile::V2::ComprehensiveDocumentSerializer.new(object.document, scope: scope, root: false) if object.document
  end

  def document_title
    object.document.standard_document.name
  end
end

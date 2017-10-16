class DocumentUpdateOwnerSerializer < ActiveModel::Serializer
  attributes :id, :standard_folder, :standard_base_document, :document_owners, :business_documents

  has_many :document_owners

  def standard_folder
    return nil if object.standard_document.blank?
    standard_folder = object.standard_document.standard_folder_standard_documents.first.standard_folder
    StandardBaseDocumentPermissionSerializer.new(standard_folder, { :scope => scope, :root => false })
  end

  def standard_base_document
    return nil if object.standard_document.blank?
    StandardBaseDocumentPermissionSerializer.new(object.standard_document, { :scope => scope, :root => false })
  end

  def business_documents
    ActiveModel::ArraySerializer.new(object.business_documents,
      each_serializer: ::Api::Mobile::V2::BusinessDocumentSerializer,
      scope: scope,
      root: false
    )
  end
end
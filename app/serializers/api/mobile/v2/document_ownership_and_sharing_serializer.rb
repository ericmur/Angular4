class Api::Mobile::V2::DocumentOwnershipAndSharingSerializer < ActiveModel::Serializer
  attributes :id, :owners, :sharees, :business_documents, :standard_folder, :standard_base_document

  def owners
    ActiveModel::ArraySerializer.new(object.document_owners,
      each_serializer: DocumentOwnerSerializer,
      scope: scope,
      root: false
    )
  end

  def sharees
    doc_owner_uids = object.document_owners.only_connected_owners.map(&:owner_id)
    sharee_list = object.symmetric_keys.where.not(created_for_user_id: doc_owner_uids).where.not(created_for_user_id: nil)
    ActiveModel::ArraySerializer.new(sharee_list,
      each_serializer: ::Api::Mobile::V2::DocumentShareeSerializer,
      scope: scope,
      root: false
    )
  end

  def business_documents
    ActiveModel::ArraySerializer.new(object.business_documents,
      each_serializer: ::Api::Mobile::V2::BusinessDocumentSerializer,
      scope: scope,
      root: false
    )
  end

  def standard_folder
    return nil if object.standard_document.blank?
    standard_folder = object.standard_document.standard_folder_standard_documents.first.standard_folder
    StandardBaseDocumentPermissionSerializer.new(standard_folder, { :scope => scope, :root => false })
  end

  def standard_base_document
    return nil if object.standard_document.blank?
    StandardBaseDocumentPermissionSerializer.new(object.standard_document, { :scope => scope, :root => false })
  end
end
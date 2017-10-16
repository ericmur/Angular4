# This document serializer is used to construct ChatDocument
# Should not be used for live request
class Api::Mobile::V2::DynamicDocumentSerializer < ActiveModel::Serializer
  include ActionView::Helpers::DateHelper

  attributes :id, :standard_document_id, :consumer_id, :standard_document_fields
  attributes :pages, :favorite_id, :last_modified_at_str, :state, :original_file_name, :original_file_key
  attributes :source, :suggested_standard_document_id, :file_content_type, :document_access_request
  attributes :standard_folder_standard_documents, :standard_folder, :standard_base_document, :sharees
  attributes :document_permissions

  has_many :pages
  has_many :document_owners

  delegate :current_user, to: :scope

  # Override default value of `original_file_name`
  def original_file_name
    object.original_file_name.nil? ? "" : object.original_file_name
  end

  def document_access_request
    access_request = object.document_access_requests.created_by(current_user.id).first
    DocumentAccessRequestSerializer.new(access_request, { scope: scope, root: false })
  end

  def document_permissions
    ActiveModel::ArraySerializer.new(object.document_permissions.for_user_id(current_user.id),
      each_serializer: ::Api::Mobile::V2::DocumentPermissionSerializer,
      scope: scope
    )
  end

  def favorite_id
    favorite = object.favorites.where(consumer_id: current_user.id).first
    favorite ? favorite.id : nil
  end

  def last_modified_at_str
    if object.last_modified_at
      "Over " + time_ago_in_words(object.last_modified_at) + " Old"
    else
      "Over " + time_ago_in_words(object.created_at) + " Old"
    end
  end

  def standard_folder
    return nil if object.standard_document.blank?
    standard_folder = object.standard_document.standard_folder_standard_documents.first.standard_folder
    Api::Mobile::V2::StandardFolderSerializer.new(standard_folder, { :scope => scope, :root => false })
  end

  def standard_base_document
    return nil if object.standard_document.blank?
    Api::Mobile::V2::StandardBaseDocumentSerializer.new(object.standard_document, { :scope => scope, :root => false })
  end

  def standard_folder_standard_documents
    return [] if object.standard_document.blank?
    ActiveModel::ArraySerializer.new(object.standard_document.standard_folder_standard_documents,
      each_serializer: Api::Mobile::V2::StandardFolderStandardDocumentSerializer,
      scope: scope)
  end

  def business_documents
    ActiveModel::ArraySerializer.new(object.business_documents,
      each_serializer: Api::Mobile::V2::BusinessDocumentSerializer,
      scope: scope,
      root: false
    )
  end

  def sharees
    users = User.where(id: object.all_sharees_ids_except_system)
    # Note: Using as_json to pass in `document` to `serialization_options`
    # By using as_json, `avatar` attribute inside ShareeSerializer is not generate. But we are not using `avatar`, so it's cool
    ActiveModel::ArraySerializer.new(users, each_serializer: ShareeSerializer, scope: scope, root: false).as_json(document: object)
  end

  # Return non-secure fields with value
  # Return secure fields without the value
  def standard_document_fields
    if object.standard_document
      doc_fields = object.standard_document.standard_document_fields + object.document_fields
      ActiveModel::ArraySerializer.new(doc_fields,
        each_serializer: BaseDocumentFieldSerializer,
        scope: { current_user: current_user, document_id: object.id, skip_secure_value: true },
        root: false)
    else
      []
    end
  end
end
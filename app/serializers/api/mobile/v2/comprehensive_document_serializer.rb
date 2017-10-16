# This serializer should be used for live request serializer for document object
# Should include SymmetricKey and StandardFields (secure + non-secure)
# May also need to add support attributes for older version
class Api::Mobile::V2::ComprehensiveDocumentSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  include SerializerStandardFields
  include ActionView::Helpers::DateHelper

  attributes :id, :standard_document_id, :consumer_id, :standard_document_fields, :symmetric_key
  attributes :pages, :favorite_id, :last_modified_at_str, :state, :original_file_name, :original_file_key
  attributes :source, :suggested_standard_document_id, :file_content_type, :document_access_request
  attributes :standard_folder_standard_documents, :standard_folder, :standard_base_document, :business_documents, :businesses, :document_permissions

  # Support attributes for older app version
  attributes :standard_document_name, :standard_document_size, :standard_document_rank, :standard_document_description

  has_many :pages
  has_many :document_owners

  delegate :current_user, to: :scope

  # Override default value of `original_file_name`
  def original_file_name
    object.original_file_name.nil? ? "" : object.original_file_name
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

  def businesses
    ActiveModel::ArraySerializer.new(object.businesses,
      each_serializer: Api::Mobile::V2::BusinessSerializer,
      scope: scope,
      root: false
    )
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

  # Support attribute for older app version
  def standard_document_name
   object.standard_document ? object.standard_document.name : nil
  end

  # Support attribute for older app version
  def standard_document_description
    object.standard_document ? object.standard_document.description : nil
  end

  # Support attribute for older app version
  def standard_document_rank
    object.standard_document && object.standard_document.rank || 0
  end

  # Support attribute for older app version
  def standard_document_size
    object.standard_document ? object.standard_document.size : nil
  end
end
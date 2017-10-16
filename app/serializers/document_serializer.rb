# This serializer might need to be removed after V2 cache service
# Should be replaced by Api::Mobile::V2::ComprehensiveDocumentSerializer
class DocumentSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  include SerializerStandardFields
  include ActionView::Helpers::DateHelper

  attributes :id, :standard_document_id, :consumer_id, :symmetric_key, :standard_document_fields, :pages, :favorite_id, :last_modified_at_str
  attributes :state, :original_file_name, :original_file_key, :source, :suggested_standard_document_id, :file_content_type, :document_access_request
  
  attributes :notification_level

  has_many :pages
  has_many :document_owners

  delegate :current_user, to: :scope

  attributes :standard_folder, :standard_base_document

  def standard_folder
    return nil if object.standard_document.blank?
    standard_folder = object.standard_document.standard_folder_standard_documents.first.standard_folder
    StandardBaseDocumentPermissionSerializer.new(standard_folder, { :scope => scope, :root => false })
  end

  def standard_base_document
    return nil if object.standard_document.blank?
    StandardBaseDocumentPermissionSerializer.new(object.standard_document, { :scope => scope, :root => false })
  end

  # Note: backward compatibility for older client version
  def first_expiring_value
    @expiring_value ||= object.document_field_values.order(notification_level: :desc).first
  end

  # Note: backward compatibility for older client version
  def notification_level
    unless first_expiring_value.nil?
      return first_expiring_value.notification_level
    end
    return 0
  end

  def document_access_request
    access_request = object.document_access_requests.created_by(current_user.id).first
    DocumentAccessRequestSerializer.new(access_request, { :scope => scope, :root => false })
  end

  def favorite_id
    favorite = object.favorites.where(consumer_id: current_user.id).first
    favorite ? favorite.id : nil
  end

  def last_modified_at_str
    if object.last_modified_at
      "Over " + time_ago_in_words(object.last_modified_at) + " Old"
    end
  end

end

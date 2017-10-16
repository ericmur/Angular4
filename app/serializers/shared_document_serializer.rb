# Check if this serializer is still required after V2 document cache service
# Otherwise replace with Api::Mobile::V2::ComprehensiveDocumentSerializer
class SharedDocumentSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  include SerializerStandardFields
  include ActionView::Helpers::DateHelper

  attributes :id, :standard_document_id, :consumer_id, :symmetric_key, :standard_document_fields, :pages, :favorite_id, :last_modified_at_str
  attributes :state, :original_file_name, :original_file_key, :final_file_key, :source, :suggested_standard_document_id, :file_content_type
  attributes :standard_document_name, :standard_document_size, :standard_document_rank, :standard_document_description, :standard_folder

  # Note: backward compatibility for older client version
  attributes :notification_level

  has_many :pages
  has_many :document_owners

  delegate :current_user, to: :scope

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

  def favorite_id
    favorite = object.favorites.where(consumer_id: current_user.id).first
    favorite ? favorite.id : nil
  end

  def last_modified_at_str
    if object.last_modified_at
      "Over " + time_ago_in_words(object.last_modified_at) + " Old"
    end
  end

  def standard_folder
    return nil if object.standard_document.blank?
    standard_folder = object.standard_document.standard_folder_standard_documents.first.standard_folder
    SharedDocumentStandardFolderSerializer.new(standard_folder, { :scope => scope, :root => false })
  end

  def standard_document_name
   object.standard_document ? object.standard_document.name : nil
  end

  def standard_document_description
    object.standard_document ? object.standard_document.description : nil
  end

  def standard_document_rank
    object.standard_document && object.standard_document.rank || 0
  end

  def standard_document_size
    object.standard_document ? object.standard_document.size : nil
  end
end

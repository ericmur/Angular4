# Check if this serializer is still require
# Otherwise replace with Api::Mobile::V2::ComprehensiveDocumentSerializer
class SearchDetailSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  include SerializerStandardFields

  attributes :id, :standard_document_id, :consumer_id, :symmetric_key, 
    :standard_document_fields, :pages, :standard_document

  has_many :pages

  delegate :current_user, to: :scope

  def standard_document
    object.standard_document
  end

end
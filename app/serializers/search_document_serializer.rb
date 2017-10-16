# Check if this serializer is still required after V2 document cache service
# Otherwise replace with Api::Mobile::V2::ComprehensiveDocumentSerializer
class SearchDocumentSerializer < ActiveModel::Serializer
  include SerializerStandardFields

  attributes :id, :standard_document_field, :pages_count

  delegate :current_user, to: :scope

  def pages_count
    object.pages.count
  end

  def standard_document_field
    standard_document_fields.first
  end

end
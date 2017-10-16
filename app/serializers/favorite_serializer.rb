class FavoriteSerializer < ActiveModel::Serializer
  include SerializerSymmetricKey
  include SerializerStandardFields
  include Iconable

  attributes :id, :document, :consumer_id, :standard_document, :icon_url, :icon_name

  delegate :current_user, to: :scope

  def standard_document
    object.document.standard_document
  end

  def standard_folder
    object.document.standard_document.standard_folder_standard_documents.first.standard_folder
  end

  def iconable_object
    standard_folder
  end

  def document
    DocumentSerializer.new(object.document, { :scope => scope, :root => false })
  end

end

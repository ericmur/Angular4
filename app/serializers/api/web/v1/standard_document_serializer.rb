class Api::Web::V1::StandardDocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :category_name, :standard_folder_id, :consumer_id, :documents_count,
             :standard_folder_name, :client_uploaded_documents_count

  has_many :document_uploaders, each_serializer: Api::Web::V1::DocumentUploaderSerializer

  def documents_count
    object.documents.size
  end

  def client_uploaded_documents_count
    return nil unless object.respond_to?(:doc_count)

    object.doc_count
  end

  def category_name
    return nil unless object.respond_to?(:category_name)

    object.category_name
  end

  def standard_folder_id
    return nil unless object.respond_to?(:standard_folder_id)

    object.standard_folder_id
  end

  def standard_folder_name
    return nil unless (object.respond_to?(:standard_folder) and object.standard_folder)

    object.standard_folder.name
  end

  def consumer_id
    return nil unless object.respond_to?(:consumer_id)

    object.consumer_id
  end
end

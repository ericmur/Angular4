class Api::Web::V1::EmailDocumentSerializer < ActiveModel::Serializer
  attributes :id, :original_file_name, :original_file_key, :file_content_type,
             :created_at, :state, :storage_size, :name

  has_one :email

  def name
    object.standard_document_id ? object.standard_document.name : ""
  end

end

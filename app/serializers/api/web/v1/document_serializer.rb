class Api::Web::V1::DocumentSerializer < Api::Web::V1::BaseDocumentSerializer
  attributes :id, :original_file_name, :final_file_key, :file_content_type,
             :created_at, :state, :storage_size, :name, :symmetric_key, :source,
             :standard_document_id, :standard_folder_name, :standard_document_name,
             :document_owners_count, :first_document_owner_name, :first_page_s3_key,
             :pages_count, :have_access

  has_many :document_owners, serializer: Api::Web::V1::DocumentOwnerSerializer

  def name
    object.standard_document_id ? object.standard_document.name : ""
  end

end

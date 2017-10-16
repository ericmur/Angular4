class Api::Web::V1::ChatDocumentSerializer < Api::Web::V1::BaseDocumentSerializer
  attributes :id, :standard_document_id, :original_file_name, :original_file_key,
             :symmetric_key, :state, :storage_size, :file_content_type, :final_file_key,
             :first_page_s3_key, :pages_count, :standard_folder_name, :standard_document_name,
             :document_owners_count, :first_document_owner_name, :have_access, :document_fields_count

  def document_fields_count
    object.document_fields.size
  end

end

class Api::Web::V1::QuickDocumentSerializer < Api::Web::V1::BaseDocumentSerializer
  attributes :id, :original_file_name, :original_file_key, :file_content_type,
             :created_at, :state, :storage_size, :name, :standard_folder_name,
             :standard_document_name, :document_fields, :first_page_s3_key,
             :have_access, :standard_document_id, :final_file_key, :first_document_owner_name,
             :source, :uploader_email, :updated_at

  has_one  :standard_document

  def name
    object.standard_document_id ? object.standard_document.name : ""
  end

  def document_fields
    fields = Api::Web::V1::DocumentFieldsQuery.new(scope, {document_id: object.id}).get_document_fields
    ActiveModel::ArraySerializer.new(fields, :each_serializer => Api::Web::V1::DocumentFieldsSerializer, :scope => scope)
  end

  def standard_document
    return StandardDocument.select(
      'standard_base_documents.*, (
        SELECT
          standard_folder_standard_documents.standard_folder_id
        FROM
          standard_folder_standard_documents
        WHERE
          standard_folder_standard_documents.standard_base_document_id = standard_base_documents.id
        GROUP BY
          standard_folder_standard_documents.id
        LIMIT 1
      ) as standard_folder_id'
    )
    .group('standard_base_documents.id')
    .find_by(id: object.standard_document.id) if object.standard_document
  end

end

class Api::Mobile::V2::SecureDocumentsController < Api::Mobile::V2::ApiController
  before_action :load_user_password_hash

  def index
    documents = ::Api::Mobile::V2::DocumentsQuery.new(current_user, params).get_documents.select('documents.id, documents.standard_document_id, documents.group_rank, documents.created_at')
    render status: 200, json: documents, each_serializer: ::Api::Mobile::V2::DocumentDetailSecureSerializer, root: 'documents'
  end
end

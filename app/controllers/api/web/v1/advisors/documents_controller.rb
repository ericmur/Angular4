class Api::Web::V1::Advisors::DocumentsController < Api::Web::V1::ApiController
  before_action :set_attached_documents, only: :documents_via_email
  before_action :set_document_uploaded_via_email, only: :document_via_email

  def documents_via_email
    render status: 200, json: @documents, each_serializer: Api::Web::V1::EmailDocumentSerializer
  end

  def document_via_email
    if @document
      render status: 200, json: @document, serializer: ::Api::Web::V1::DocumentSerializer
    else
      render status: 404, json: {}
    end
  end

  private

  def set_attached_documents
    @documents = ::Api::Web::V1::DocumentsQuery.new(current_advisor, params).get_attached_documents
  end

  def set_document_uploaded_via_email
    @document = ::Api::Web::V1::DocumentsQuery.new(current_advisor, params).get_document_uploaded_via_email
  end
end

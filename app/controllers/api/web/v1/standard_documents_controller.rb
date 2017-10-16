class Api::Web::V1::StandardDocumentsController < Api::Web::V1::ApiController
  before_action :set_base_documents,    only: :index
  before_action :set_standard_document, only: :show

  def index
    render status: 200, json: @base_documents, each_serializer: ::Api::Web::V1::StandardDocumentSerializer,
      meta: { pages_count: @pages_count }
  end

  def show
    if @standard_document
      render status: 200, json: @standard_document, serializer: ::Api::Web::V1::StandardDocumentSerializer
    else
      render status: 404, json: {}
    end
  end

  private

  def set_base_documents
    standard_documents_query = Api::Web::V1::StandardDocumentsQuery.new(current_advisor, params)

    @base_documents = standard_documents_query.set_base_documents
    @pages_count = standard_documents_query.pages_count
  end

  def set_standard_document
    @standard_document = StandardDocument.find_by(id: params[:id])
  end

end

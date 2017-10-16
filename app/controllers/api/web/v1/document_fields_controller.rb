class Api::Web::V1::DocumentFieldsController < Api::Web::V1::ApiController
  before_action :set_document_fields, only: :index

  def index
    render status: 200, json: @document_fields, each_serializer: ::Api::Web::V1::DocumentFieldsSerializer
  end

  private

  def set_document_fields
    @document_fields = ::Api::Web::V1::DocumentFieldsQuery
      .new(current_advisor, params).get_document_fields
  end
end

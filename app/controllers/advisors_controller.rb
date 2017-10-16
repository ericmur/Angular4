class AdvisorsController < ApplicationController
  before_action :load_advisor_and_client, only: [:documents]
  before_action :load_user_password_hash, only: [:documents]

  def show
    @advisor = User.with_standard_category.find(params[:id])
    respond_to do |format|
      format.json { render json: @advisor, serializer: AdvisorSerializer, root: 'advisor' }
    end
  end

  def documents
    all_documents_ids = Api::Web::V1::DocumentsQuery.new(@advisor, :client_id => @client.id).get_all_documents_ids
    @client_documents = Document.where(id: all_documents_ids).where.not(standard_document_id: nil)

    respond_to do |format|
      format.json { render json: @client_documents, each_serializer: Api::Mobile::V2::ComprehensiveDocumentSerializer, root: 'documents' }
    end
  end

  private

  def load_advisor_and_client
    @advisor = User.with_standard_category.find(params[:id])
    @client = @advisor.clients_as_advisor.find_by_consumer_id(self.current_user.id)
  end
end

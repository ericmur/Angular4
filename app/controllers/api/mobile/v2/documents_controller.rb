class Api::Mobile::V2::DocumentsController < Api::Mobile::V2::ApiController
  before_action :load_user_password_hash, only: [:index]
  before_action :load_document, only: [:owners, :sharees]

  def index
    self.current_user.run_migrations
    @documents_json = DocumentCacheService.new(current_user, params).get_user_documents_json
    render status: 200, json: @documents_json
  end

  def check_status
    @documents = Document.where(id: params[:document_ids]).select('id, state')
    render status: 200, json: @documents, each_serializer: ::Api::Mobile::V2::DocumentStatusSerializer, root: 'documents'
  end

  def owners
    render status: 200, json: @document, serializer: ::Api::Mobile::V2::DocumentOwnershipAndSharingSerializer, root: 'document'
  end

  def sharees
    render status: 200, json: @document, serializer: ::Api::Mobile::V2::DocumentOwnershipAndSharingSerializer, root: 'document'
  end

  private

  def load_document
    @document = Document.find(params[:id])
    unless @document.symmetric_keys.where(created_for_user_id: current_user.id).exists?
      render json: { errors: ["You don't have the permissions to view this document"] }, status: :not_acceptable
    end
  end
end

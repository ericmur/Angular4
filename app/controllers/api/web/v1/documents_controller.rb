class Api::Web::V1::DocumentsController < Api::Web::V1::ApiController
  before_action :set_document,  only: [:show, :destroy, :update_category]
  before_action :set_advisor_password_hash, only: :create
  before_action :search_result, only: :search

  def index
    if params[:structure_type] == GroupUser::FLAT
      set_documents_for_contact
    else
      set_documents
    end

    if @documents
      render status: 200, json: @documents, each_serializer: ::Api::Web::V1::QuickDocumentSerializer,
        meta: { pages_count: @pages_count }
    else
      render status: 404, json: {}
    end
  end

  def show
    if @document
      render status: 200, json: @document, serializer: ::Api::Web::V1::DocumentSerializer
    else
      render status: 404, json: {}
    end
  end

  def create
    document = ::Api::Web::V1::DocumentBuilder
      .new(current_advisor, document_params, params).create_document

    if document.persisted?
      DocumentCacheService.update_cache([:document], document.consumer_ids_for_owners)

      render status: 201, json: document, serializer: ::Api::Web::V1::DocumentSerializer
    else
      render status: 422, json: document.errors
    end
  end

  def destroy
    if @document
      consumer_ids_for_owners = @document.consumer_ids_for_owners
      @document.destroy
      DocumentCacheService.update_cache([:document], consumer_ids_for_owners)

      render status: 204, json: nil
    else
      render status: 404, json: {}
    end
  end

  def complete_upload
    document = ::Api::Web::V1::DocumentBuilder
      .new(current_advisor, document_params, params).complete_document_upload

    if document.errors.empty? && document.complete_upload && document.save
      result = true

      if document.is_source_chat? && document.document_extension.pdf_file?
        document.share_with_system_for_duration(:by_user_id => current_advisor.id)
        result = document.start_convertation!
      elsif !document.is_source_chat?
        document.share_with_system_for_duration(:by_user_id => current_advisor.id) #Share with DocytBot so it can convert pdf => images for Consumers
        result = document.start_convertation!
      end

      if result
        DocumentCacheService.update_cache([:document], document.consumer_ids_for_owners)
        render status: 200, json: document, serializer: ::Api::Web::V1::QuickDocumentSerializer, root: :document
      else
        render status: 422, json: document.errors
      end
    else
      render status: 422, json: document.errors
    end
  end

  def update_category
    document = ::Api::Web::V1::DocumentBuilder
      .new(current_advisor, document_params, params).update_category

    if document && document.errors.empty?
      document.generate_folder_settings
      if document.standard_document && document.standard_document.consumer_id.present?
        DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], document.consumer_ids_for_owners)
      else
        DocumentCacheService.update_cache([:document, :folder_setting], document.consumer_ids_for_owners)
      end
      render status: 200, json: document, serializer: ::Api::Web::V1::QuickDocumentSerializer, root: :document
    else
      render status: 422, json: document.errors
    end
  end

  def assign
    documents_assignment_service = ::Api::Web::V1::DocumentAssignmentService
      .new(current_advisor, params[:client_id], document_assignment_params, params)
    documents = documents_assignment_service.assign_to_client

    if documents_assignment_service.errors.any?
      render status: 422, json: documents_assignment_service.errors
    else
      documents.each do |document|
        document.generate_folder_settings
        if document.standard_document && document.standard_document.consumer_id.present?
          DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], document.consumer_ids_for_owners)
        else
          DocumentCacheService.update_cache([:document, :folder_setting], document.consumer_ids_for_owners)
        end
      end
      render status: 200, json: documents, each_serializer: ::Api::Web::V1::QuickDocumentSerializer
    end
  end

  def search
    render status: 200, json: @documents, each_serializer: ::Api::Web::V1::SearchDocumentSerializer
  end

  private

  def search_result
    @documents = ::Api::Web::V1::DocumentsQuery.new(current_advisor, params).search_documents
  end

  def set_documents
    documents_query = ::Api::Web::V1::DocumentsQuery.new(current_advisor, params)

    @documents   = documents_query.get_documents
    @pages_count = documents_query.pages_count
  end

  def set_documents_for_contact
    @documents = ::Api::Web::V1::DocumentsQuery.new(current_advisor, params).get_documents_for_contact
  end

  def set_document
    @document = ::Api::Web::V1::SymmetricKeyQuery.new(current_advisor).get_documents.where(:id => params[:id]).first
  end

  def document_assignment_params
    params.require(:shared_documents).permit(ids: [])
  end

  def document_params
    params.require(:document).permit(:current, :source, :original_file_name,
                                     :storage_size, :file_content_type,
                                     :final_file_key, :s3_object_key
                                     )
  end

  def set_advisor_password_hash
    Rails.set_user_password_hash(Rails.startup_password_hash)
  end
end

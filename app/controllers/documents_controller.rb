class DocumentsController < ApplicationController
  include UserAccessibilityForController
  skip_before_action :doorkeeper_authorize!, only: [:sns_notification]
  skip_before_action :confirm_phone!, only: [:sns_notification]
  skip_before_action :confirm_device_uuid!, only: [:sns_notification]

  before_action :only => [:create] { |c| c.send(:verify_permission_create, params) } #use send since it is a private method
  before_action :load_document, except: [:index, :new, :create, :search, :suggested, :group_reorder, :sns_notification]
  before_action :load_user_password_hash, only: [:share, :create, :show, :revoke, :search, :index, :suggested, :update, :update_sharees, :update_owners, :complete_upload, :share_with_system, :symmetric_key]
  before_action :verify_permission_for_create, only: [:create]
  before_action :verify_permission_for_edit_owner, only: [:update, :revoke, :update_owners]
  before_action :verify_permission_for_edit_sharee, only: [:update_sharees, :revoke, :share]
  before_action :verify_permission_for_deletion, only: [:destroy]
  before_action :verify_connected_group_users, only: [:create]
  before_action :verify_aws_notification, only: [:sns_notification]
  before_action :check_non_connected_group_users, only: [:update_sharees]
  before_action :verify_permission_to_update_sharees, only: [:update_sharees]

  #Whenever params[:user_id] is passed we should modify this controller to return documents for that user
  def index
    if params[:category] and (params[:category].strip == "1" or params[:category].downcase.strip == "true")
      self.current_user.run_migrations
      user_document_cache = UserDocumentCache.document_cache_for(current_user)
      docs = user_document_cache.document_json

      respond_to do |format|
        format.json { render :json => docs }
      end
    else
      docs = self.current_user.document_ownerships.map(&:document)
      respond_to do |format|
        format.json { render :json => docs }
      end
    end
  end

  def suggested
    docs = self.current_user.uploaded_documents_via_email.limit(10).union(self.current_user.suggested_documents_for_upload.limit(10)).order(created_at: :desc)
    respond_to do |format|
      format.json { render :json => docs }
    end
  end

  def search
    docs = StandardFolderStandardDocument.joins(:standard_base_document, :standard_folder)
    docs = docs.where("(standard_folders_standard_folder_standard_documents.name ILIKE ?) OR (standard_base_documents.name ILIKE ?)", "%#{params[:q]}%", "%#{params[:q]}%")
    docs = docs.order("standard_folder_standard_documents.rank ASC")

    respond_to do |format|
      format.json { render :json => docs, each_serializer: SearchResultSerializer }
    end
  end

  def create
    @document = ::Api::Mobile::V2::DocumentBuilder.new(current_user, document_params, params).create_document

    if @document.persisted? && @document.errors.empty?
      DocumentCacheService.update_cache([:document, :folder_setting], @document.consumer_ids_for_owners)
      respond_to do |format|
        format.json { render :json => @document }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def sharees
    sharees = @document.sharees_for_documents
    respond_to do |format|
      format.json { render :json => sharees, :each_serializer => ShareeSerializer, :root => 'sharees', document: @document }
    end
  end

  def owners
    owners = @document.document_owners
    respond_to do |format|
      format.json { render :json => owners, :root => 'document_owners' }
    end
  end

  #List all pages of the document
  def show
    respond_to do |format|
      if params[:search_detail].present?
        format.json { render :json => @document, serializer: SearchDetailSerializer }
      elsif params[:final_file_key].present?
        format.json { render :json => { "final_file_key" => @document.final_file_key }.to_json }
      else
        format.json { render :json => @document, serializer: Api::Mobile::V2::ComprehensiveDocumentSerializer, root: 'document' }
      end
    end
  end

  # This will only return document without symmetric keys
  # Meant to load document without access for chat message
  def info
    @document = Document.find(params[:id])
    respond_to do |format|
      format.json { render :json => @document, serializer: Api::Mobile::V2::DynamicDocumentSerializer, root: 'document' }
    end
  end

  def symmetric_key
    @symmetric_key = @document.symmetric_keys.where(created_for_user_id: current_user.id).first

    respond_to do |format|
      format.json { render :json => @symmetric_key, serializer: SymmetricKeySerializer }
    end
  end

  def update
    document = ::Api::Mobile::V2::DocumentBuilder.new(current_user, document_params, params).update_category

    if document.errors.empty?
      DocumentCacheService.update_cache([:document], document.consumer_ids_for_owners)
      render status: :ok, json: document, serializer: Api::Mobile::V2::ComprehensiveDocumentSerializer, root: 'document'
    else
      render status: :not_acceptable, json: { errors: document.errors.full_messages }
    end
  end
  
  def destroy
    consumer_ids_for_owners = @document.consumer_ids_for_owners
    @document.destroy
    if @document.suggested_standard_document_id and @document.standard_document_id.nil?
      #Archive as rejection of DocytBot's suggested category
      @document.archive!
    end

    consumer_ids_for_owners.each do |uid|
      user = User.find_by_id(uid)
      user.recalculate_storage_size
      user.recalculate_page_count
    end

    DocumentCacheService.update_cache([:document], consumer_ids_for_owners)
    
    respond_to do |format|
      format.json { render :json => { }, status: :no_content }
    end
  end

  def update_sharees
    consumer_ids_for_owners = @document.consumer_ids_for_owners
    builder = Api::Mobile::V2::DocumentBuilder.new(current_user, {}, params)

    respond_to do |format|
      if builder.update_sharees!(@document)
        if !@document.has_user_access?
          @document.destroy
          format.json { render :json => { deleted: true } }
        elsif !@document.accessible_by_me?(current_user)
          # local deletion, document may still shared with other user
          format.json { render :json => { deleted: true } }
        else
          format.json { render :json => { updated: true } }
        end
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end

    consumer_ids_for_owners += @document.consumer_ids_for_owners
    if @document.standard_document && @document.standard_document.consumer_id.present?
      DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], consumer_ids_for_owners.uniq)
    else
      DocumentCacheService.update_cache([:document, :folder_setting], consumer_ids_for_owners.uniq)
    end
  end

  def update_owners
    consumer_ids_for_owners = @document.consumer_ids_for_owners
    builder = Api::Mobile::V2::DocumentBuilder.new(current_user, {}, params)

    respond_to do |format|
      if builder.update_owners!(@document)
        if @document.should_destroyed?(current_user)
          @document.destroy
          format.json { render :json => { deleted: true } }
        elsif !@document.accessible_by_me?(current_user)
          # local deletion, document may still shared with other user
          format.json { render :json => { deleted: true } }
        else
          format.json { render json: @document, serializer: DocumentUpdateOwnerSerializer, root: 'document' }
        end
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end

    consumer_ids_for_owners += @document.consumer_ids_for_owners
    if @document.standard_document && @document.standard_document.consumer_id.present?
      DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], consumer_ids_for_owners.uniq)
    else
      DocumentCacheService.update_cache([:document, :folder_setting], consumer_ids_for_owners.uniq)
    end
  end

  def share
    respond_to do |format|
      if @document.share_with(:by_user_id => self.current_user.id, :with_user_id => params[:user_id])
        @document.generate_standard_base_document_permissions
        @document.generate_folder_settings
        DocumentCacheService.update_cache([:document, :folder_setting], @document.consumer_ids_for_owners)
        format.json { render :json => @document }
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def revoke
    consumer_ids_for_owners = @document.consumer_ids_for_owners
    respond_to do |format|
      if @document.revoke_sharing(:with_user_id => params[:user_id])
        DocumentCacheService.update_cache([:document], consumer_ids_for_owners)
        format.json { render :json => @document }
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def start_upload
    @document.original_file_key = params[:s3_object_key]
    respond_to do |format|
      if @document.start_upload && @document.save
        DocumentCacheService.update_cache([:document], @document.consumer_ids_for_owners)
        format.json { render :json => { status: @document.state } }
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def object_keys
    respond_to do |format|
      format.json { render json: @document, serializer: DocumentObjectKeysSerializer, root: 'document' }
    end
  end

  #This will be triggered for documents uploaded via Service Provider web portal. For those documents they are still uploaded using traditional complete_upload action which works better for them. SNS notification is only best for background upload in iPhone
  def complete_upload
    @symmetric_key = @document.symmetric_keys.for_user_access(current_user.id).first

    @document.original_file_key = params[:s3_object_key]
    respond_to do |format|
      if @document.complete_upload && @document.save
        DocumentCacheService.update_cache([:document], @document.consumer_ids_for_owners)
        format.json { render :json => { status: @document.state } }
      else
        format.json { render :json => { :errors => @document.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def group_reorder
    cache_users_to_updates = []
    params[:documents].each do |doc_hash|
      document = Document.find(doc_hash['id'])
      document.update_column(:group_rank, doc_hash['n'].to_i)
      cache_users_to_updates << document.all_sharees_ids_except_system
    end

    DocumentCacheService.update_cache([:document], cache_users_to_updates.flatten) if cache_users_to_updates.present?

    respond_to do |format|
      format.json { render json: { status: true } }
    end
  end

  def sns_notification
    with_sns_notification("DocumentUploadBot") do |message|
      message["Records"].each do |record_hash|
        next if record_hash["s3"].blank?
        process_document_completion_from_sns_notification(record_hash)
      end if message["Records"].present?
    end
    render nothing: true
  end

  def share_with_system
    @document.share_with_system_for_duration(:by_user_id => current_user.id)
    render nothing: true
  end

  private

  def verify_permission_to_update_sharees
    unless @document.uploader_id == current_user.id || @document.document_owners.where(owner: current_user).exists? || @document.sharee_editable_by?(current_user)
      message = I18n.t('errors.document.cannot_share_document')
      if params[:document_sharees].present? && params[:document_sharees].select{|a| a[:delete].present? || a['delete'].present? }.present?
        message = I18n.t('errors.document.cannot_revoke_sharee')
      end
      respond_to do |format|
        format.json { render json: { errors: [message] }, status: :not_acceptable }
      end
    end
  end

  def process_document_completion_from_sns_notification(record_hash)
    object_key = record_hash["s3"]["object"]["key"]
    return unless object_key.match('Document-')
    numbers = object_key.scan(/\d+/)
    document_id = numbers.first
    document = Document.find_by_id(document_id)
    return if document.nil?
    document.process_completion_from_sns_notification(object_key)
  end

  def document_params
    if params[:document].present? #When updating a document (for eg. just updating owners) it is possible this is not needed
      params.require(:document).permit(:standard_document_id, 
                                       :current, :source, :original_file_name, :storage_size)
    end
  end

  def verify_permission_for_create
    standard_document = StandardDocument.find(document_params[:standard_document_id])
    unless standard_document.is_writeable_by_user?(current_user)
      render status: 422, json: { errors: ['You don\'t have the permissions to create this type of document'] }
    end
  end

  def verify_permission_for_deletion
    unless @document.destroyable_by?(current_user)
      render status: 406, json: { errors: ['You don\'t have the permissions to delete a document for this user'] }
    end
  end

  def verify_permission_for_edit_owner
    unless @document.owner_editable_by?(current_user) || @document.saveable_from_external_service_by?(current_user)
      if params[:action] == 'revoke'
        render status: 406, json: { errors: ['You don\'t have the permissions to revoke anyone\'s access to this document'] }
      else
        render status: 406, json: { errors: ['You don\'t have permissions to modify document\'s owners'] }
      end
    end
  end

  def verify_permission_for_edit_sharee
    unless @document.sharee_editable_by?(current_user)
      render status: 406, json: { errors: ['You don\'t have the permissions to add/remove access to this document'] }
    end
  end

  def load_document
    @document = Document.find(params[:id])
    unless @document.symmetric_keys.where(created_for_user_id: current_user.id).exists?
      if params[:action] == 'destroy'
        render status: 406, json: { errors: ['You don\'t have the permissions to delete a document for this user'] }
      elsif params[:action] == 'revoke'
        render status: 406, json: { errors: ['You don\'t have the permissions to revoke anyone\'s access to this document'] }
      elsif params[:action] == 'update'
        render status: 406, json: { errors: ['You don\'t have permissions to modify document\'s owners'] }
      else
        render status: 406, json: { errors: ['You don\'t have the permissions to view this document'] }
      end
    end
  end

  def verify_connected_group_users
    params[:document_owners].each do |owner_hash| 
      if owner_hash["owner_type"] == "User"
        if owner_hash["owner_id"].to_i == current_user.id
          next
        end
        group_user_exists = current_user.group_users_as_group_owner.exists?(user_id: owner_hash["owner_id"])
        client_exists = current_user.clients_as_advisor.exists?(consumer_id: owner_hash["owner_id"])
        unless group_user_exists || client_exists
          respond_to do |format|
            format.json { render :json => { :errors => [I18n.t('errors.group_user.disconnected')] }, :status => :not_acceptable }
          end
          return
        end
      elsif owner_hash["owner_type"] == "Client"
        unless current_user.clients_as_advisor.exists?(id: owner_hash["owner_id"])
          respond_to do |format|
            format.json { render :json => { :errors => [I18n.t('errors.group_user.disconnected')] }, :status => :not_acceptable }
          end
          return
        end
      else
        unless current_user.group_users_as_group_owner.exists?(id: owner_hash["owner_id"])
          respond_to do |format|
            format.json { render :json => { :errors => [I18n.t('errors.group_user.disconnected')] }, :status => :not_acceptable }
          end
          return
        end
      end
    end if params[:document_owners].present?
  end

  def check_non_connected_group_users
    revoked_sharee_ids = []

    params[:document_sharees].each do |sharees_hash|
      if sharees_hash['user_type'] == 'GroupUser'
        group_user = current_user.group_users_as_group_owner.find_by(sharees_hash['user_id'])
        sharee_id = group_user.user_id
      else
        sharee_id = sharees_hash['user_id'].to_i
      end
      if sharees_hash['delete'].present?
        revoked_sharee_ids << sharee_id
      end
    end if params[:document_sharees].present?

    if revoked_sharee_ids.flatten.select{|k| k == current_user.id }.first
      removed_contacts_names = []
      my_connected_group_users_ids = current_user.group_users_as_group_owner.where.not(user_id: nil).select('user_id').map(&:user_id)
      my_connected_document_owners_ids = @document.document_owners.only_connected_owners.where(owner_id: my_connected_group_users_ids).map(&:owner_id)

      my_document_access_requests = @document.document_access_requests.where(uploader_id: current_user.id, created_by_user_id: my_connected_document_owners_ids)
      if my_document_access_requests.exists?
        removed_contacts_names += my_document_access_requests.map{|r| r.created_by_user.first_name }
      end

      my_non_connected_group_user_ids = current_user.group_users_as_group_owner.where(user_id: nil).select('id').map(&:id)
      my_non_connected_document_owners = @document.document_owners.only_not_connected_owners.where(owner_id: my_non_connected_group_user_ids)

      if my_non_connected_document_owners.exists?
        removed_contacts_names += my_non_connected_document_owners.map{|o| o.owner.first_name }
      end

      unless removed_contacts_names.blank?
        respond_to do |format|
          format.json { render :json => { :errors => ["One of your contacts: #{removed_contacts_names.join(', ')} is an owner of this document but does not have access to it. Please remove them as owner or give them access before removing yourself"] }, :status => :not_acceptable }
        end
      end
    end
  end

end

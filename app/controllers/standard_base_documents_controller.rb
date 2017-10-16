class StandardBaseDocumentsController < ApplicationController
  include UserAccessibilityForController
  respond_to :json
  before_action :load_standard_base_document, :only => [:update, :destroy, :set_hidden, :set_displayed]
  before_filter :only => [:create, :update] { |c| c.send(:verify_permission_create, params) } #use send since it is a private method
  before_action :verify_permissions_for_deletion, :only => [:destroy]
  before_action :load_standard_folder_setting, only: [:set_hidden, :set_displayed]
  before_action :build_user_folder_setting, only: [:set_hidden, :set_displayed]

  def index
    if params[:first_time]
      stdocs = FirstTimeStandardDocument.by_account_type(params[:account_type_id])
      respond_to do |format|
        format.json { render :json => stdocs, :each_serializer => FirstTimeStandardDocumentSerializer, :root => 'first_time_standard_documents', :status => :ok }
      end
    end
  end
  
  def create
    standard_folder_id = params[:standard_base_document][:standard_folder_id]
    @standard_document = StandardDocumentBuilder.new(current_user, standard_base_document_params, params[:owners], [], standard_folder_id).create_standard_document
    if @standard_document.persisted?
      DocumentCacheService.update_cache([:standard_document], @standard_document.consumer_ids_for_owners)
      render status: 200, json: @standard_document.standard_folder_standard_documents.first
    else
      render status: 422, json: { errors: @standard_document.errors.full_messages }
    end
  end

  def update
    if params[:owners].present?
      params[:owners].each do |owner_hash|
        if owner_hash["owner_type"] == "GroupUser"
          group_user = GroupUser.find(owner_hash['owner_id'])
          @standard_base_document.owners.create!(owner: group_user) if @standard_base_document.owners.where(owner: group_user).count == 0
        elsif owner_hash["owner_type"] == "Consumer" or owner_hash["owner_type"] == "User"
          user = User.find(owner_hash['owner_id'])
          @standard_base_document.owners.create!(owner: user) if @standard_base_document.owners.where(owner: user).count == 0
        end
      end
    else
      user = User.find(self.current_user.id)
      @standard_base_document.owners.create!(owner: user) if @standard_base_document.owners.where(owner: user).count == 0
    end

    DocumentCacheService.update_cache([:standard_document], @standard_document.consumer_ids_for_owners)

    respond_to do |format|
      format.json { render :json => { owners: @standard_base_document.owners.map{|o| { owner_type: o.owner_type, owner_id: o.owner_id } } }, :status => :ok }
    end
  end

  def destroy
    consumer_ids_for_owners = @standard_document.consumer_ids_for_owners
    @standard_base_document.owners.where(owner: @folder_structure_owner).destroy_all
    @standard_base_document.permissions.where(folder_structure_owner: @folder_structure_owner, user: current_user).destroy_all

    if @standard_base_document.owners.count == 0
      @standard_base_document.destroy
    end

    DocumentCacheService.update_cache([:standard_document], consumer_ids_for_owners)

    if @standard_base_document.destroyed?
      render status: 200, json: { deleted: true }
    else
      render status: 200, json: @standard_base_document, serializer: StandardBaseDocumentPermissionSerializer, root: 'standard_base_document'
    end
  end

  def set_hidden
    @user_folder_setting.displayed = false
    respond_to do |format|
      if @user_folder_setting.save
        DocumentCacheService.update_cache([:folder_setting], [current_user.id])
        format.json { render nothing: true, status: :ok }
      else
        format.json { render json: { errors: @user_folder_setting.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def set_displayed
    @user_folder_setting.displayed = true
    respond_to do |format|
      if @user_folder_setting.save
        DocumentCacheService.update_cache([:folder_setting], [current_user.id])
        format.json { render nothing: true, status: :ok }
      else
        format.json { render json: { errors: @user_folder_setting.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_standard_folder_setting
    if params[:group_user_id].present?
      @folder_owner = current_user.group_users_as_group_owner.find(params[:group_user_id])
      @user_folder_setting = current_user.user_folder_settings.for_standard_base_document(@standard_base_document.id).for_folder_owner(@folder_owner).first
    else
      @folder_owner = current_user
      @user_folder_setting = current_user.user_folder_settings.for_standard_base_document(@standard_base_document.id).for_folder_owner(current_user).first
    end
  end

  def build_user_folder_setting
    if @user_folder_setting.nil?
      @user_folder_setting = current_user.user_folder_settings.build(user: current_user, folder_owner: @folder_owner, standard_base_document: @standard_base_document, displayed: false)
    end
  end

  # Not the best practice to put it all together in here
  # However this method is only required for destroy action
  def verify_permissions_for_deletion
    if params[:folder_structure_owner_id].blank?
      render status: 422, json: { errors: ["Sorry cannot do that."] }; return
    end

    if params[:folder_structure_owner_type] == 'GroupUser'
      @folder_structure_owner = GroupUser.find(params[:folder_structure_owner_id])
    else
      @folder_structure_owner = User.find(params[:folder_structure_owner_id])
    end

    unless @standard_base_document.is_destroyable_by_user?(current_user, @folder_structure_owner)
      render status: 422, json: { errors: ["You don't have the permissions to delete this document type."] }; return
    end

    if @standard_base_document.documents.joins(:document_owners).where(document_owners: {owner: @folder_structure_owner}).exists?
      render status: 422, json: { errors: ["Selected category is not empty."] }
    end
  end

  def standard_base_document_params
    params.require(:standard_base_document).permit(:name, :with_pages)
  end
  
  def load_standard_base_document
    @standard_base_document = StandardBaseDocument.where(:id => params[:id]).first
  end

  def verify_permission_destroy
    if @standard_base_document.is_editable_by_user?(self.current_user)
      return true
    else
      respond_to do |format|
        format.json { render :json => { :errors => ["You don't have the permissions to delete a document type for this user"] }, :status => :not_acceptable }
      end
    end
  end
end

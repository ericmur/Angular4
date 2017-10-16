class StandardFoldersController < ApplicationController
  include UserAccessibilityForController
  respond_to :json
  before_action :load_standard_folder, only: [:set_hidden, :set_displayed, :destroy]
  before_action :load_standard_folder_setting, only: [:set_hidden, :set_displayed]
  before_action :build_user_folder_setting, only: [:set_hidden, :set_displayed]
  before_action :verify_permissions_for_deletion, only: [:destroy]
  before_action only: [:create, :update] { |c| c.send(:verify_permission_create, params) } #use send since it is a private method

  def create
    @standard_folder = StandardFolderBuilder.new(current_user, standard_folder_params, params[:owners], params).create_folder
    if @standard_folder.persisted?
      DocumentCacheService.update_cache([:standard_folder], @standard_folder.consumer_ids_for_owners)

      render status: 200, json: @standard_folder
    else
      render status: 422, json: { errors: @standard_folder.errors.full_messages }
    end
  end

  def destroy
    consumer_ids_for_owners = @standard_folder.consumer_ids_for_owners

    @standard_folder.owners.where(owner: @folder_structure_owner).destroy_all
    @standard_folder.permissions.where(folder_structure_owner: @folder_structure_owner, user: current_user).destroy_all

    if @standard_folder.owners.count == 0
      @standard_folder.destroy
    end

    DocumentCacheService.update_cache([:standard_folder], consumer_ids_for_owners)

    if @standard_folder.destroyed?
      render status: 200, json: { deleted: true }
    else
      render status: 200, json: @standard_folder, serializer: StandardBaseDocumentPermissionSerializer, root: 'standard_base_document'
    end
  end

  def set_hidden
    @user_folder_setting.displayed = false
    if @user_folder_setting.save
      DocumentCacheService.update_cache([:folder_setting], [current_user.id])

      render status: 200, nothing: true
    else
      render status: 422, json: { errors: @user_folder_setting.errors.full_messages }
    end
  end

  def set_displayed
    @user_folder_setting.displayed = true
    if @user_folder_setting.save
      DocumentCacheService.update_cache([:folder_setting], [current_user.id])

      render status: 200, nothing: true
    else
      render status: 422, json: { errors: @user_folder_setting.errors.full_messages }
    end
  end

  private

    def load_standard_folder
      @standard_folder = StandardFolder.find(params[:id])
    end

    def load_standard_folder_setting
      if params[:group_user_id].present?
        @folder_owner = current_user.group_users_as_group_owner.find(params[:group_user_id])
      else
        @folder_owner = current_user
      end
      @user_folder_setting = current_user.user_folder_settings
        .for_standard_base_document(@standard_folder.id)
        .for_folder_owner(@folder_owner)
        .first
    end

    def build_user_folder_setting
      if @user_folder_setting.nil?
        @user_folder_setting = current_user.user_folder_settings.build(user: current_user, folder_owner: @folder_owner, standard_base_document: @standard_folder, displayed: false)
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

      unless @standard_folder.is_destroyable_by_user?(current_user, @folder_structure_owner)
        render status: 422, json: { errors: ["You don't have the permissions to delete this category."] }; return
      end

      owned_std_docs = StandardDocument.where(id: @standard_folder.standard_folder_standard_documents.map(&:standard_base_document_id)).owned_by(@folder_structure_owner)
      if owned_std_docs.exists?
        render status: 422, json: { errors: ["Selected category is not empty."] }
      end
    end

    def standard_folder_params
      params.require(:standard_folder).permit(:name, :description)
    end

end
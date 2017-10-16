class Api::Mobile::V2::StandardBaseDocumentsController < Api::Mobile::V2::ApiController
  before_action :load_standard_base_document, only: [:set_hidden, :set_displayed, :destroy]
  before_action :load_folder_setting, only: [:set_hidden, :set_displayed]
  before_action :build_folder_setting, only: [:set_hidden, :set_displayed]
  before_action :verify_permissions_for_deletion, only: [:destroy]

  def destroy
    consumer_ids_for_owners = @standard_base_document.consumer_ids_for_owners
    cache_type = @standard_base_document.type.underscore.to_sym

    @standard_base_document.owners.where(owner: @folder_structure_owner).destroy_all
    @standard_base_document.permissions.where(folder_structure_owner: @folder_structure_owner, user: current_user).destroy_all

    if @standard_base_document.owners.count == 0
      @standard_base_document.destroy
    end

    DocumentCacheService.update_cache([cache_type], consumer_ids_for_owners)

    if @standard_base_document.destroyed?
      render status: 200, json: { deleted: true }
    else
      render status: 200, json: @standard_base_document, serializer: StandardBaseDocumentPermissionSerializer, root: 'standard_base_document'
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

    def load_standard_base_document
      @standard_base_document = StandardBaseDocument.find(params[:id])
    end

    def load_folder_setting
      # when loading folder_owner, we will directly lookup to it's model
      if params[:group_user_id].present?
        @folder_owner = GroupUser.find(params[:group_user_id])
      elsif params[:client_id].present?
        @folder_owner = Client.find(params[:client_id])
      elsif params[:business_id].present?
        @folder_owner = Business.find(params[:business_id])
      else
        @folder_owner = current_user
      end
      @user_folder_setting = current_user.user_folder_settings
        .for_standard_base_document(@standard_base_document.id)
        .for_folder_owner(@folder_owner)
        .first
    end

    def build_folder_setting
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
      elsif params[:folder_structure_owner_type] == 'Client'
        @folder_structure_owner = Client.find(params[:folder_structure_owner_id])
      elsif params[:folder_structure_owner_type] == 'Business'
        @folder_structure_owner = Business.find(params[:folder_structure_owner_id])
      else
        @folder_structure_owner = User.find(params[:folder_structure_owner_id])
      end

      unless @standard_base_document.is_destroyable_by_user?(current_user, @folder_structure_owner)
        render status: 422, json: { errors: ["You don't have the permissions to delete this category."] }; return
      end

      if @standard_base_document.type == "StandardFolder"
        owned_std_docs = StandardDocument.where(id: @standard_base_document.standard_folder_standard_documents.map(&:standard_base_document_id)).owned_by(@folder_structure_owner)
        if owned_std_docs.exists?
          render status: 422, json: { errors: ["Selected category is not empty."] }
        end
      end
    end

end
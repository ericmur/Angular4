class Api::Mobile::V2::StandardFoldersController < Api::Mobile::V2::ApiController
  include UserAccessibilityForController
  before_action only: [:create, :update] { |c| c.send(:verify_permission_create, params) } #use send since it is a private method

  def index
    @standard_folders_json = DocumentCacheService.new(current_user, params).get_standard_folders_json
    render status: 200, json: @standard_folders_json
  end

  def create
    @standard_folder = StandardFolderBuilder.new(current_user, standard_folder_params, params[:owners], params).create_folder

    if @standard_folder.persisted?
      DocumentCacheService.update_cache([:standard_folder], @standard_folder.consumer_ids_for_owners)

      render status: 200, json: @standard_folder, serializer: ::Api::Mobile::V2::StandardFolderSerializer, root: 'standard_folder'
    else
      render status: 422, json: { errors: @standard_folder.errors.full_messages }
    end
  end

  private

    def standard_folder_params
      params.require(:standard_folder).permit(:name, :description)
    end
end

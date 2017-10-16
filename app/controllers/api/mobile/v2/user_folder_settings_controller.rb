class Api::Mobile::V2::UserFolderSettingsController < Api::Mobile::V2::ApiController
  def index
    user_folder_settings_json = DocumentCacheService.new(current_user, params).get_user_folder_settings_json
    render status: 200, json: user_folder_settings_json
  end
end
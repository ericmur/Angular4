class DocumentCache::UserFolderSettingCacheService
  include Mixins::DocumentCacheHelper

  def initialize(user, params, store_in_background=true)
    @user = user
    @params = params
    @store_in_background = store_in_background
  end

  def resource
    UserFolderSetting.where(user_id: @user.id)
  end

  def update_version
    create_or_update_cache_version
    if @store_in_background == true
      Resque.enqueue UserFolderSettingCacheUpdateJob, @user.id
    else
      build_json
    end
  end

  def build_json
    verify_user!

    cache_version = find_or_create_cache_version

    user_folder_settings_json = continue_with_optional_logger do
      ActiveModel::ArraySerializer.new(resource,
        root: 'user_folder_settings',
        each_serializer: Api::Mobile::V2::UserFolderSettingSerializer,
        scope: scope
      ).as_json
    end

    user_folder_settings_json.merge!({ cache_version: cache_version.version })

    output_json = user_folder_settings_json.to_json

    if @store_in_background == true
      Resque.enqueue UserFolderSettingCacheUpdateJob, @user.id
    else
      unless cache_version_exists?(USER_FOLDER_SETTING_CACHE, cache_version)
        store_json(USER_FOLDER_SETTING_CACHE, cache_version, output_json)
      end
      cleanup_old_cache(USER_FOLDER_SETTING_CACHE, cache_version)
    end

    output_json
  end

  def cache_version_resource
    DocumentCache::UserFolderSettingJsonVersion.where(user_id: @user.id).order(version: :asc)
  end

  def cache_json_resource
    DocumentCache::UserFolderSettingJson.where(user_id: @user.id).order(version: :asc)
  end

  def create_cache_version
    DocumentCache::UserFolderSettingJsonVersion.create(user_id: @user.id, version: 0)
  end

end
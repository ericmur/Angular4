class DocumentCache::UserStandardFolderCacheService
  include Mixins::DocumentCacheHelper

  def initialize(user, params, store_in_background=true)
    @user = user
    @params = params
    @store_in_background = store_in_background
  end

  def resource
    StandardFolder.only_category.only_custom.viewable_by_user(@user.id).order(rank: :asc)
  end

  def update_version
    create_or_update_cache_version
    if @store_in_background == true
      Resque.enqueue UserStandardFolderCacheUpdateJob, @user.id
    else
      build_json
    end
  end

  def build_json
    verify_user!
    cache_version = find_or_create_cache_version
    standard_folders_json = continue_with_optional_logger do
      ActiveModel::ArraySerializer.new(resource,
        root: 'standard_folders',
        each_serializer: Api::Mobile::V2::StandardFolderSerializer,
        scope: scope
      ).as_json
    end
    standard_folders_json.merge!({ cache_version: cache_version.version })
    output_json = standard_folders_json.to_json

    if @store_in_background == true
      Resque.enqueue UserStandardFolderCacheUpdateJob, @user.id
    else
      unless cache_version_exists?(USER_STANDARD_FOLDER_CACHE, cache_version)
        store_json(USER_STANDARD_FOLDER_CACHE, cache_version, output_json)
      end
      cleanup_old_cache(USER_STANDARD_FOLDER_CACHE, cache_version)
    end

    output_json
  end

  def cache_version_resource
    DocumentCache::UserStandardFolderJsonVersion.where(user_id: @user.id).order(version: :asc)
  end

  def cache_json_resource
    DocumentCache::UserStandardFolderJson.where(user_id: @user.id).order(version: :asc)
  end

  def create_cache_version
    DocumentCache::UserStandardFolderJsonVersion.create(user_id: @user.id, version: 0)
  end
end
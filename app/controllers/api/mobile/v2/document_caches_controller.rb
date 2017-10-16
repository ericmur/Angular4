class Api::Mobile::V2::DocumentCachesController < Api::Mobile::V2::ApiController
  def check_version
    cache_type = params[:cache_type]
    mobile_cache_version = params[:mobile_cache_version]
    case cache_type
    when Mixins::DocumentCacheHelper::SYSTEM_STANDARD_FOLDER_CACHE
      cache_version = DocumentCache::SystemStandardFolderJsonVersion.get_latest_cache_for_system
      cache_data = DocumentCache::SystemStandardFolderJson.get_latest_cache_for_system
    when Mixins::DocumentCacheHelper::SYSTEM_STANDARD_DOCUMENT_CACHE
      cache_version = DocumentCache::SystemStandardDocumentJsonVersion.get_latest_cache_for_system
      cache_data = DocumentCache::SystemStandardDocumentJson.get_latest_cache_for_system
    when Mixins::DocumentCacheHelper::USER_STANDARD_FOLDER_CACHE
      cache_version = DocumentCache::UserStandardFolderJsonVersion.get_latest_cache_for_user(current_user)
      cache_data = DocumentCache::UserStandardFolderJson.get_latest_cache_for_user(current_user)
    when Mixins::DocumentCacheHelper::USER_STANDARD_DOCUMENT_CACHE
      cache_version = DocumentCache::UserStandardDocumentJsonVersion.get_latest_cache_for_user(current_user)
      cache_data = DocumentCache::UserStandardDocumentJson.get_latest_cache_for_user(current_user)
    when Mixins::DocumentCacheHelper::USER_FOLDER_SETTING_CACHE
      cache_version = DocumentCache::UserFolderSettingJsonVersion.get_latest_cache_for_user(current_user)
      cache_data = DocumentCache::UserFolderSettingJson.get_latest_cache_for_user(current_user)
    when Mixins::DocumentCacheHelper::USER_DOCUMENT_CACHE
      cache_version = DocumentCache::UserDocumentJsonVersion.get_latest_cache_for_user(current_user)
      cache_data = DocumentCache::UserDocumentJson.get_latest_cache_for_user(current_user)
    when Mixins::DocumentCacheHelper::ALIAS_CACHE
      cache_version = DocumentCache::AliasJsonVersion.get_latest_cache_for_system
      cache_data = DocumentCache::AliasJson.get_latest_cache_for_system
    else
      cache_data = nil
      cache_version = nil
    end

    if cache_data && cache_version
      if cache_version.version == cache_data.version && cache_version.version == mobile_cache_version.to_i
        render status: 200, nothing: true
      else
        render status: 422, nothing: true
      end
    else
      render status: 422, nothing: true
    end
  end
end
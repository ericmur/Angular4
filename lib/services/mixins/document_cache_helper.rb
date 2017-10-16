require 'serializer_scope'

module Mixins::DocumentCacheHelper
  SYSTEM_STANDARD_FOLDER_CACHE = 'SystemStandardFolder'
  SYSTEM_STANDARD_DOCUMENT_CACHE = 'SystemStandardDocument'
  USER_STANDARD_FOLDER_CACHE = 'UserStandardFolder'
  USER_STANDARD_DOCUMENT_CACHE = 'UserStandardDocument'
  USER_FOLDER_SETTING_CACHE = 'UserFolderSetting'
  USER_DOCUMENT_CACHE = 'UserDocument'
  ALIAS_CACHE = 'AliasCache'

  def scope
    scope = SerializerScope.new
    scope.current_user = @user
    scope.params = @params
    scope
  end

  def get_json
    cache_version = cache_version_resource.last
    cache_json = cache_json_resource.last

    if cache_version.present? && cache_json.present? && cache_version.version == cache_json.version
      return cache_json.data
    else
      return build_json
    end
  end

  def continue_with_optional_logger
    if ENV['SILENCE_SERIALIZER'].present?
      Rails.logger.silence do
        yield
      end
    else
      yield
    end
  end

  def verify_user!
    raise "User is required to generate user's document caches" if @user.blank?
  end

  def find_or_create_cache_version
    cache_version = cache_version_resource.last
    unless cache_version.present?
      cache_version = create_cache_version
    end
    cache_version
  end

  def create_or_update_cache_version
    cache_version = cache_version_resource.last
    if cache_version.present?
      cache_version.version += 1
      cache_version.save
    else
      cache_version = create_cache_version
    end
    cache_version
  end

  def cache_version_exists?(cache_type, cache_version)
    case cache_type
    when SYSTEM_STANDARD_FOLDER_CACHE
      DocumentCache::SystemStandardFolderJson.where(version: cache_version.version).exists?
    when SYSTEM_STANDARD_DOCUMENT_CACHE
      DocumentCache::SystemStandardDocumentJson.where(version: cache_version.version).exists?
    when USER_STANDARD_FOLDER_CACHE
      DocumentCache::UserStandardFolderJson.where(user_id: @user.id, version: cache_version.version).exists?
    when USER_STANDARD_DOCUMENT_CACHE
      DocumentCache::UserStandardDocumentJson.where(user_id: @user.id, version: cache_version.version).exists?
    when USER_FOLDER_SETTING_CACHE
      DocumentCache::UserFolderSettingJson.where(user_id: @user.id, version: cache_version.version).exists?
    when USER_DOCUMENT_CACHE
      DocumentCache::UserDocumentJson.where(user_id: @user.id, version: cache_version.version).exists?
    when ALIAS_CACHE
      DocumentCache::AliasJson.where(version: cache_version.version).exists?
    else
      raise "Invalid cache type: #{cache_type}"
    end
  end

  def store_json(cache_type, cache_version, data)
    case cache_type
    when SYSTEM_STANDARD_FOLDER_CACHE
      DocumentCache::SystemStandardFolderJson.create!(version: cache_version.version, data: data)
    when SYSTEM_STANDARD_DOCUMENT_CACHE
      DocumentCache::SystemStandardDocumentJson.create!(version: cache_version.version, data: data)
    when USER_STANDARD_FOLDER_CACHE
      DocumentCache::UserStandardFolderJson.create!(user_id: @user.id, version: cache_version.version, data: data)
    when USER_STANDARD_DOCUMENT_CACHE
      DocumentCache::UserStandardDocumentJson.create!(user_id: @user.id, version: cache_version.version, data: data)
    when USER_FOLDER_SETTING_CACHE
      DocumentCache::UserFolderSettingJson.create!(user_id: @user.id, version: cache_version.version, data: data)
    when USER_DOCUMENT_CACHE
      DocumentCache::UserDocumentJson.create!(user_id: @user.id, version: cache_version.version, data: data)
    when ALIAS_CACHE
      DocumentCache::AliasJson.create!(version: cache_version.version, data: data)
    else
      raise "Invalid cache type: #{cache_type}"
    end
  end

  def cleanup_old_cache(cache_type, cache_version)
    case cache_type
    when SYSTEM_STANDARD_FOLDER_CACHE
      DocumentCache::SystemStandardFolderJsonVersion.where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::SystemStandardFolderJson.where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when SYSTEM_STANDARD_DOCUMENT_CACHE
      DocumentCache::SystemStandardDocumentJsonVersion.where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::SystemStandardDocumentJson.where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when USER_STANDARD_FOLDER_CACHE
      DocumentCache::UserStandardFolderJsonVersion.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::UserStandardFolderJson.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when USER_STANDARD_DOCUMENT_CACHE
      DocumentCache::UserStandardDocumentJsonVersion.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::UserStandardDocumentJson.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when USER_FOLDER_SETTING_CACHE
      DocumentCache::UserFolderSettingJsonVersion.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::UserFolderSettingJson.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when USER_DOCUMENT_CACHE
      DocumentCache::UserDocumentJsonVersion.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::UserDocumentJson.where(user_id: @user.id).where({'version' => {'$lt' => cache_version.version }}).destroy_all
    when ALIAS_CACHE
      DocumentCache::AliasJsonVersion.where({'version' => {'$lt' => cache_version.version }}).destroy_all
      DocumentCache::AliasJson.where({'version' => {'$lt' => cache_version.version }}).destroy_all
    else
      raise "Invalid cache type: #{cache_type}"
    end
  end
end
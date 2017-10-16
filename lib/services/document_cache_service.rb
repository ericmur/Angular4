require 'serializer_scope'
require 'document_cache/system_standard_folder_cache_service'
require 'document_cache/system_standard_document_cache_service'
require 'document_cache/user_standard_folder_cache_service'
require 'document_cache/user_standard_document_cache_service'
require 'document_cache/user_document_cache_service'
require 'document_cache/alias_cache_service'

class DocumentCacheService

  def initialize(user, params={})
    @user = user
    @params = params ? params : {}
    Rails.set_mobile_app_version(@user.mobile_app_version) if @user.present?
  end

  def self.update_cache(cache_types, user_ids, params={})
    user_ids = user_ids.flatten.uniq
    # Update V1 JSON cache service
    # V1 does not include folder_setting in JSON cache
    unless cache_types.size == 1 && cache_types[0] == :folder_setting
      UserDocumentCache.update_cache(user_ids) unless user_ids.blank?
    end

    user_ids.each do |user_id|
      user = User.find_by_id(user_id)
      if user
        cache_service = DocumentCacheService.new(user, params)
        
        #Users Prior to 1.1.7 do not need the V2 cache. They can suck it with the old cache or just upgrade their app into this new utopia of V2 cache
        next unless Rails.mobile_app_version && Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.7")
        
        cache_types.each do |cache_type|
          cache_service.enqueue_update_user_document_caches(cache_type.to_sym)
        end
      end
    end
  end

  def verify_user_folder_settings_cache
    cache_service = DocumentCache::UserFolderSettingCacheService.new(@user, @params, false)
    db_resources = cache_service.resource
    json_cache = cache_service.cache_json_resource.order(version: :asc).last

    if json_cache.blank?
      # Cache not yet created. User might be newly registered user.
      return
    end

    json_data = JSON.parse(json_cache.data)
    resource_ids_from_db = cache_service.resource.map(&:id)
    resource_ids_from_mongo = json_data['user_folder_settings'].map{|d| d['id'] }

    verify_resource_ids(:folder_setting, resource_ids_from_db, resource_ids_from_mongo)
  end

  def verify_user_standard_documents_cache
    cache_service = DocumentCache::UserStandardDocumentCacheService.new(@user, @params, false)
    db_resources = cache_service.resource
    json_cache = cache_service.cache_json_resource.order(version: :asc).last

    if json_cache.blank?
      # Cache not yet created. User might be newly registered user.
      return
    end

    json_data = JSON.parse(json_cache.data)
    resource_ids_from_db = cache_service.resource.map(&:id)
    resource_ids_from_mongo = json_data['standard_base_documents'].map{|d| d['id'] }

    verify_resource_ids(:standard_document, resource_ids_from_db, resource_ids_from_mongo)
  end

  def verify_user_standard_folders_cache
    cache_service = DocumentCache::UserStandardFolderCacheService.new(@user, @params, false)
    db_resources = cache_service.resource
    json_cache = cache_service.cache_json_resource.order(version: :asc).last

    if json_cache.blank?
      # Cache not yet created. User might be newly registered user.
      return
    end

    json_data = JSON.parse(json_cache.data)
    resource_ids_from_db = cache_service.resource.map(&:id)
    resource_ids_from_mongo = json_data['standard_folders'].map{|d| d['id'] }

    verify_resource_ids(:standard_folder, resource_ids_from_db, resource_ids_from_mongo)
  end

  def verify_user_documents_cache
    cache_service = DocumentCache::UserDocumentCacheService.new(@user, @params, false)
    db_resources = cache_service.resource
    json_cache = cache_service.cache_json_resource.order(version: :asc).last

    if json_cache.blank?
      # Cache not yet created. User might be newly registered user.
      return
    end

    json_data = JSON.parse(json_cache.data)
    resource_ids_from_db = cache_service.resource.map(&:id)
    resource_ids_from_mongo = json_data['documents'].map{|d| d['id'] }

    verify_resource_ids(:document, resource_ids_from_db, resource_ids_from_mongo)
  end

  def verify_resource_ids(cache_type, resource_ids_from_db, resource_ids_from_mongo)
    should_update_cache = false
    # should check if resource is in db but not in cache
    check_resource_not_in_cache = resource_ids_from_db.count > 0

    resource_ids_from_mongo.each do |resource_id|
      if resource_ids_from_db.include?(resource_id)
        resource_ids_from_db.reject!{|d| d == resource_id }
      else
        check_resource_not_in_cache = false
        should_update_cache = true
        break
      end
    end

    if check_resource_not_in_cache
      unless resource_ids_from_db.empty?
        should_update_cache = true
      end
    end

    if should_update_cache
      SlackHelper.ping({channel: "#warnings", username: "DocumentCache", message: "Invalid #{cache_type.to_s} cache found for User: #{@user.id}."})
      DocumentCacheService.update_cache([cache_type], [@user.id], @params)
    end
  end

  def only_system?
    ['true', '1'].include?(@params[:only_system].to_s)
  end

  def get_user_folder_settings_json
    DocumentCache::UserFolderSettingCacheService.new(@user, @params).get_json
  end

  def get_standard_folders_json
    if only_system?
      DocumentCache::SystemStandardFolderCacheService.new(@params).get_json
    else
      DocumentCache::UserStandardFolderCacheService.new(@user, @params).get_json
    end
  end

  def get_standard_base_documents_json
    if only_system?
      DocumentCache::SystemStandardDocumentCacheService.new(@params).get_json
    else
      DocumentCache::UserStandardDocumentCacheService.new(@user, @params).get_json
    end
  end

  def get_aliases_json
    DocumentCache::AliasCacheService.new(@params).get_json
  end

  def get_user_documents_json
    DocumentCache::UserDocumentCacheService.new(@user, @params).get_json
  end

  def update_system_document_caches
    DocumentCache::SystemStandardFolderCacheService.new(@params).build_json
    DocumentCache::SystemStandardDocumentCacheService.new(@params).build_json
    DocumentCache::AliasCacheService.new(@params).build_json
    nil
  end

  def enqueue_update_user_document_caches(document_type=nil, store_in_background=true)
    log_message = "Queue. Cache update for User: #{@user.id} Type: #{document_type}"
    Rails.logger.info log_message
    ap log_message if Rails.env.development?
    if document_type.blank?
      DocumentCache::UserStandardFolderCacheService.new(@user, @params, store_in_background).update_version
      DocumentCache::UserStandardDocumentCacheService.new(@user, @params, store_in_background).update_version
      DocumentCache::UserDocumentCacheService.new(@user, @params, store_in_background).update_version
      DocumentCache::UserFolderSettingCacheService.new(@user, @params, store_in_background).update_version
    elsif document_type.to_sym == :standard_folder
      DocumentCache::UserStandardFolderCacheService.new(@user, @params, store_in_background).update_version
    elsif document_type.to_sym == :standard_document
      DocumentCache::UserStandardDocumentCacheService.new(@user, @params, store_in_background).update_version
    elsif document_type.to_sym == :document
      DocumentCache::UserDocumentCacheService.new(@user, @params, store_in_background).update_version
    elsif document_type.to_sym == :folder_setting
      DocumentCache::UserFolderSettingCacheService.new(@user, @params, store_in_background).update_version
    end
    nil
  end

  def update_user_document_caches(document_type=nil)
    log_message = "Processing queue. Cache for User: #{@user.id} Type: #{document_type}"
    Rails.logger.info log_message
    ap log_message if Rails.env.development?
    if document_type.blank?
      DocumentCache::UserStandardFolderCacheService.new(@user, @params, false).build_json
      DocumentCache::UserStandardDocumentCacheService.new(@user, @params, false).build_json
      DocumentCache::UserDocumentCacheService.new(@user, @params, false).build_json
      DocumentCache::UserFolderSettingCacheService.new(@user, @params, false).get_json
    elsif document_type.to_sym == :standard_folder
      DocumentCache::UserStandardFolderCacheService.new(@user, @params, false).build_json
    elsif document_type.to_sym == :standard_document
      DocumentCache::UserStandardDocumentCacheService.new(@user, @params, false).build_json
    elsif document_type.to_sym == :document
      DocumentCache::UserDocumentCacheService.new(@user, @params, false).build_json
    elsif document_type.to_sym == :folder_setting
      DocumentCache::UserFolderSettingCacheService.new(@user, @params, false).get_json
    end
    nil
  end


end

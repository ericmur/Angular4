namespace :document_cache do
  desc "Update System's Document JSON"
  task update_system_document_json: :environment do
    DocumentCacheService.new(nil, { only_system: 1 }).update_system_document_caches
  end

  desc "Update all Users Document JSON"
  task :update_users_document_json => :environment do |t, args|
    User.all.each do |consumer|
      DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [consumer.id])
    end
  end

  desc "Update users standard folder/document"
  task update_custom_standard_base_document_json: :environment do
    User.find_each do |consumer|
      DocumentCacheService.update_cache([:standard_folder, :standard_document], [consumer.id])
    end
  end

  desc "Update User's Document JSON"
  task :update_user_document_json, [:user_id] => :environment do |t, args|
    consumer = User.find(args[:user_id])
    DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [consumer.id])
  end

  desc "Cleanup document caches. Bumper version will be maitained."
  task cleanup: :environment do
    DocumentCache::UserDocumentJson.destroy_all
    DocumentCache::UserFolderSettingJson.destroy_all
    DocumentCache::UserStandardDocumentJson.destroy_all
    DocumentCache::UserStandardFolderJson.destroy_all
    DocumentCache::SystemStandardFolderJson.destroy_all
    DocumentCache::SystemStandardDocumentJson.destroy_all
  end

  desc "Cleanup user's document caches. Bumper version will be maitained."
  task cleanup_user_caches: :environment do
    DocumentCache::UserDocumentJson.destroy_all
    DocumentCache::UserFolderSettingJson.destroy_all
    DocumentCache::UserStandardDocumentJson.destroy_all
    DocumentCache::UserStandardFolderJson.destroy_all
  end
end

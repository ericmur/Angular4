class UserFolderSettingCacheUpdateJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(user_id)
    DocumentCacheService.new(User.find(user_id), {}).update_user_document_caches(:folder_setting)
  end
end
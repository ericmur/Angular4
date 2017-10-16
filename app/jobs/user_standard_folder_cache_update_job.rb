# V2 User StandardFolder JSON Cache
class UserStandardFolderCacheUpdateJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(user_id)
    DocumentCacheService.new(User.find(user_id), {}).update_user_document_caches(:standard_folder)
  end
end
# V2 User Documents JSON Cache
class UserDocumentCacheUpdateJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(user_id)
    DocumentCacheService.new(User.find(user_id), {}).update_user_document_caches(:document)
  end
end
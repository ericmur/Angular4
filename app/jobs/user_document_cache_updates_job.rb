class UserDocumentCacheUpdatesJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(resource_id)
    user = User.find(resource_id)
    UserDocumentCache.update_document_cache_for(user.id)
  end
end

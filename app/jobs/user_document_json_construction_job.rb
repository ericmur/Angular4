class UserDocumentJsonConstructionJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(user_id)
    user_document_cache = UserDocumentCache.find_by_user_id(user_id)
    user_document_cache.generate_document_json if user_document_cache
  end
end

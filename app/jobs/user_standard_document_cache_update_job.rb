# V2 User StandardDocument JSON Cache
class UserStandardDocumentCacheUpdateJob
  include Resque::Plugins::UniqueJob
  @queue = :default

  def self.perform(user_id)
    DocumentCacheService.new(User.find(user_id), {}).update_user_document_caches(:standard_document)
  end
end
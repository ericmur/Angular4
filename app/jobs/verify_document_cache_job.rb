class VerifyDocumentCacheJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user = User.find_by_id(user_id)
    if user.present?
      cache_service = DocumentCacheService.new(user, {})
      cache_service.verify_user_documents_cache
      cache_service.verify_user_standard_documents_cache
      cache_service.verify_user_standard_folders_cache
      cache_service.verify_user_folder_settings_cache
    end
  end
end

class UserStorageSizeCounterJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user = User.find_by_id(user_id)
    if user.present?
      user.recalculate_page_count
      user.recalculate_storage_size
    end
  end
end

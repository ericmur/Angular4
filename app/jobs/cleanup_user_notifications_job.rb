class CleanupUserNotificationsJob < ActiveJob::Base
  queue_as :low

  def perform(user_id)
    user = User.find_by_id(user_id)
    user.cleanup_old_notifications if user
  end
end

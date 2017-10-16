class SendNotificationJob < ActiveJob::Base
  queue_as :send_notification

  def perform
    notifications = NotificationService.new
    notifications.search_and_send_unread_notifications
  end

end

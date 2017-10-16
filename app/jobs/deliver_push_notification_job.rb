class DeliverPushNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(notification_id)
    notification = Notification.find_by_id(notification_id)
    notification.deliver_push_notification if notification
  end
end

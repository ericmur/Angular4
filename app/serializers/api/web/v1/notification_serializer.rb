class Api::Web::V1::NotificationSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :recipient_id, :message, :notification_type, :unread,
             :created_at, :notifiable, :notifiable_type

  def notification_type
    Notification.notification_types[object.notification_type]
  end

end

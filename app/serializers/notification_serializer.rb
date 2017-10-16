class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :recipient_id, :message, :notification_type, :unread, :created_at
  attributes :notifiable_id, :notifiable_type, :sender_user, :sender_avatar

  def notification_type
    Notification.notification_types[object.notification_type]
  end

  def sender_user
    UserSerializer.new(object.sender, { :scope => scope, :root => false })
  end

  def sender_avatar
    AvatarSerializer.new(object.sender.avatar, { :scope => scope, :root => false }) if object.sender
  end
end
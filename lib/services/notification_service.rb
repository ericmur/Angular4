class NotificationService

  def search_and_send_unread_notifications
    @message_users = Messagable::MessageUser.joins(:message).where(read_at: nil, notify_at: nil)
      .where('message_users.created_at < ?', 5.minutes.ago)

    return unless @message_users.any?

    arr = []
    @message_users.each do |message_user|
      arr << [message_user.receiver, message_user.message.sender, message_user.message.chat]
    end

    arr.uniq.each do |receiver, sender, chat|
      if receiver && receiver.email
        unread_messages_count = @message_users.where('message_users.receiver_id': receiver.id, 'messages.sender_id': sender.id, 'messages.chat_id': chat.id).count
        MessageNotificationMailer.missed_message(chat.id, receiver.id, sender.id, unread_messages_count).deliver_later
      else
      end
    end

    @message_users.update_all(notify_at: Time.current)

  end

end

class NotificationServiceJob
  @queue = :high

  def self.perform(chat_id, message)
    params = {
      'chat_id':     chat_id,
      'sender_id':   message['data']['sender_id'],
      'created_at':  message['data']['created_at'],
      'receiver_id': message['data']['receiver_id'],
      'sender_type': message['data']['sender_type'],
      'type': 'New message'
    }

    FayeClientBuilder.new("/notifications", params).publish_message
  end
end

class SendPushMessageJob
  @queue = :high

  def self.perform(message_id, receiver_id)
    message  = Messagable::Message.find(message_id)
    receiver = User.find(receiver_id)
    PushMessageService.send_push_message(message, receiver)
  end
end

class MessageNotificationMailer < ApplicationMailer
  def missed_message(chat_id, receiver_id, sender_id, unread_messages_count)
    @chat = Chat.find(chat_id)
    @sender = User.find(sender_id)
    @receiver = User.find(receiver_id)

    @sender_name    = @sender.name ? @sender.name : @sender.email
    @receiver_name  = @receiver.name ? @receiver.name : @receiver.email
    @receiver_email = @receiver.email
    @unread_messages_count = unread_messages_count

    if @unread_messages_count > 1
      @subject = I18n.t('emails.subjects.new_messages', unread_count: @unread_messages_count, sender_name: @sender_name)
    else
      @subject = I18n.t('emails.subjects.new_message', sender_name: @sender_name)
    end
    
    mail(from: email_address_for(:noreply), to: @receiver_email, subject: @subject) do |format|
      format.html
    end
  end
end
